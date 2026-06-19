import SwiftUI
import FootballCore

extension MatchEventType {
    /// Full, user-facing, localized event name.
    var displayName: String {
        switch self {
        case .yellowCard: String(localized: "event.yellowCard", defaultValue: "Yellow card")
        case .redCard: String(localized: "event.redCard", defaultValue: "Red card")
        case .substitution: String(localized: "event.substitution", defaultValue: "Substitution")
        case .videoReview: String(localized: "event.var", defaultValue: "VAR")
        }
    }

    /// SF Symbol that represents the event in the timeline.
    var symbolName: String {
        switch self {
        case .yellowCard, .redCard: "rectangle.portrait.fill"
        case .substitution: "arrow.left.arrow.right"
        case .videoReview: "tv"
        }
    }

    /// Tint for the event glyph.
    var tint: Color {
        switch self {
        case .yellowCard: Color.yellow
        case .redCard: Color.live
        case .substitution: Color.pitch
        case .videoReview: Color.gray
        }
    }
}
