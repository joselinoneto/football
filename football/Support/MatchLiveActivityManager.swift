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

    /// Reconcile running activities against the live matches in `days`.
    func sync(days: [MatchDay]) {
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
            let content = ActivityContent(state: state, staleDate: nil)

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
                // Home Screen widget still carries the score.
                activities[row.id] = try? Activity.request(attributes: attributes, content: content)
            }
        }
    }
}
