import Foundation
import FootballCore

extension MatchEventType {
    /// Full, user-facing, localized event name.
    public var displayName: String {
        switch self {
        case .yellowCard: String(localized: "event.yellowCard", defaultValue: "Yellow card", bundle: .module)
        case .redCard: String(localized: "event.redCard", defaultValue: "Red card", bundle: .module)
        case .substitution: String(localized: "event.substitution", defaultValue: "Substitution", bundle: .module)
        case .videoReview: String(localized: "event.var", defaultValue: "VAR", bundle: .module)
        }
    }

    /// SF Symbol that represents the event in the timeline.
    public var symbolName: String {
        switch self {
        case .yellowCard, .redCard: "rectangle.portrait.fill"
        case .substitution: "arrow.left.arrow.right"
        case .videoReview: "tv"
        }
    }
}
