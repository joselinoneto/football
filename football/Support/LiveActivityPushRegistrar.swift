import Foundation
import ActivityKit
import FootballAPI
import FootballCore

/// Captures the APNs tokens ActivityKit vends and writes them to the Airtable
/// "Push Tokens" table, so the backend live loop can update — and start —
/// Live Activities while the app is closed.
///
/// Two token kinds:
///   - `update`: one per running activity (`activity.pushTokenUpdates`). The
///     backend pushes score updates / the end event to it, keyed by `matchID`.
///   - `start`: one per device (`pushToStartTokenUpdates`). The backend pushes a
///     `start` event so an activity begins at kickoff with the app closed.
///
/// Note: a per-activity update token can only be captured while the app is
/// running. Activities begun by a push-to-start while the app is terminated
/// register their update token the next time the app runs (via `activityUpdates`).
@MainActor
final class LiveActivityPushRegistrar {
    private let config: AirtableConfiguration
    private var observed = Set<String>()   // activity ids already being watched
    private var started = false

    init(config: AirtableConfiguration = .current) {
        self.config = config
    }

    /// Begin watching for the push-to-start token and every activity's update
    /// token. Idempotent — safe to call on each sync.
    func start() {
        guard !started else { return }
        started = true

        // Activities that already exist (adopted from a previous session) plus
        // any that appear later, including ones a push-to-start created.
        for activity in Activity<MatchActivityAttributes>.activities {
            observe(activity)
        }
        Task {
            for await activity in Activity<MatchActivityAttributes>.activityUpdates {
                observe(activity)
            }
        }

        // Per-device push-to-start token (lets the backend begin an activity).
        Task {
            for await data in Activity<MatchActivityAttributes>.pushToStartTokenUpdates {
                await upload(token: Self.hex(data), kind: "start", matchRecordID: nil)
            }
        }
    }

    /// Watch one activity's update-token stream (deduped by activity id).
    func observe(_ activity: Activity<MatchActivityAttributes>) {
        guard !observed.contains(activity.id) else { return }
        observed.insert(activity.id)
        let matchID = activity.attributes.matchID
        Task {
            for await data in activity.pushTokenUpdates {
                await upload(token: Self.hex(data), kind: "update", matchRecordID: matchID)
            }
        }
    }

    private static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    // Tag which APNs environment this build talks to, so the backend hits the
    // matching host. Xcode/debug builds use sandbox; release uses production.
    #if DEBUG
    private static let apnsEnv = "sandbox"
    #else
    private static let apnsEnv = "production"
    #endif

    private func upload(token: String, kind: String, matchRecordID: String?) async {
        var fields: [String: Any] = [
            "Token": token,
            "Kind": kind,
            "Env": Self.apnsEnv,
            "Updated": ISO8601DateFormatter().string(from: Date()),
        ]
        if let matchRecordID {
            fields["Match Record ID"] = matchRecordID
        }
        let body: [String: Any] = [
            // Upsert on Token so a rotating token replaces its old row.
            "performUpsert": ["fieldsToMergeOn": ["Token"]],
            "records": [["fields": fields]],
        ]
        let url = config.baseURL
            .appending(path: config.baseID)
            .appending(path: "Push Tokens")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }
}
