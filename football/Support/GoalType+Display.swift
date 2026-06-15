import Foundation
import FootballCore

extension GoalType {
    /// A short tag shown after the scorer's name in the timeline, e.g. "(pen)".
    /// A plain goal needs no tag, so it returns nil.
    var shortTag: String? {
        switch self {
        case .goal:
            nil
        case .penalty:
            String(localized: "goal.tag.penalty", defaultValue: "pen")
        case .ownGoal:
            String(localized: "goal.tag.ownGoal", defaultValue: "OG")
        }
    }

    /// Full, user-facing label used for accessibility.
    var displayName: String {
        switch self {
        case .goal:
            String(localized: "goal.type.goal", defaultValue: "Goal")
        case .penalty:
            String(localized: "goal.type.penalty", defaultValue: "Penalty")
        case .ownGoal:
            String(localized: "goal.type.ownGoal", defaultValue: "Own goal")
        }
    }
}
