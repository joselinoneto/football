import Foundation
import ActivityKit
import FootballCore
import FootballPresentation

/// Starts, updates, and ends a Live Activity for each match that is currently
/// in play, driven by the schedule view model's refresh hook. While the app is
/// open (or doing a background refresh) the Lock Screen / Dynamic Island stays
/// in sync with the live score and match clock.
///
/// It auto-manages one activity per live match: a match flipping to `.live`
/// starts one, score/minute changes update it, and full time ends it.
@MainActor
final class MatchLiveActivityManager {
    private var activities: [String: Activity<MatchActivityAttributes>] = [:]
    /// Content is considered stale this long after kickoff — a backstop so an
    /// activity that stops receiving updates (e.g. the backend can't reach it)
    /// no longer renders as live. Matches the backend's match window.
    private let staleWindow: TimeInterval = 150 * 60
    /// Registers APNs tokens with the backend so activities keep updating (and
    /// can start) while the app is closed.
    private let push = LiveActivityPushRegistrar()

    /// Reconcile running activities against the live matches in `days`.
    func sync(days: [MatchDay]) {
        // Start watching for push tokens (push-to-start + per-activity update
        // tokens). Idempotent; the first sync arms it.
        push.start()

        // A fresh launch or background-refresh process starts with an empty map
        // even though iOS may already be showing activities from a previous
        // session. Adopt those first so we update them instead of stacking new
        // ones on the Lock Screen.
        adoptRunningActivities()

        let liveRows = days.flatMap(\.rows).filter { $0.status == .live }
        let liveIDs = Set(liveRows.map(\.id))

        // End activities whose match is no longer live (finished or gone).
        for (id, activity) in activities where !liveIDs.contains(id) {
            Task { await activity.end(nil, dismissalPolicy: .default) }
            activities[id] = nil
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        for row in liveRows {
            let state = MatchActivityAttributes.ContentState(
                homeScore: row.home.score,
                awayScore: row.away.score,
                minute: row.minute,
                status: row.status
            )
            let content = ActivityContent(
                state: state,
                staleDate: row.kickoff.addingTimeInterval(staleWindow)
            )

            if let activity = activities[row.id] {
                Task { await activity.update(content) }
            } else {
                let attributes = MatchActivityAttributes(
                    matchID: row.id,
                    homeFlag: row.home.flag,
                    homeCode: row.home.code,
                    awayFlag: row.away.flag,
                    awayCode: row.away.code,
                    stage: row.stage,
                    venue: row.venue
                )
                // Best effort: if the system declines (disabled, budget), the
                // Home Screen widget still carries the score. `pushType: .token`
                // vends an APNs token so the backend can update this activity
                // while the app is closed.
                let activity = try? Activity.request(
                    attributes: attributes, content: content, pushType: .token
                )
                activities[row.id] = activity
                if let activity { push.observe(activity) }
            }
        }
    }

    /// Reconciles the in-memory map with the activities iOS is actually running,
    /// keeping one per match and ending any duplicates left over from earlier
    /// sessions (e.g. before this de-duplication existed).
    private func adoptRunningActivities() {
        for activity in Activity<MatchActivityAttributes>.activities {
            let id = activity.attributes.matchID
            if let tracked = activities[id], tracked.id != activity.id {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            } else {
                activities[id] = activity
                push.observe(activity)
            }
        }
    }
}
