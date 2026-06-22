import Foundation
import FootballCore

extension GoalType {
    /// A short tag shown after the scorer's name in the timeline, e.g. "(pen)".
    /// A plain goal needs no tag, so it returns nil.
    public var shortTag: String? {
        switch self {
        case .goal:
            nil
        case .penalty:
            String(localized: "goal.tag.penalty", defaultValue: "pen", bundle: .module)
        case .ownGoal:
            String(localized: "goal.tag.ownGoal", defaultValue: "OG", bundle: .module)
        }
    }

    /// Full, user-facing label used for accessibility.
    public var displayName: String {
        switch self {
        case .goal:
            String(localized: "goal.type.goal", defaultValue: "Goal", bundle: .module)
        case .penalty:
            String(localized: "goal.type.penalty", defaultValue: "Penalty", bundle: .module)
        case .ownGoal:
            String(localized: "goal.type.ownGoal", defaultValue: "Own goal", bundle: .module)
        }
    }
}
