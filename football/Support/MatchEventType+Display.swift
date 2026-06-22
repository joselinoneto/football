import SwiftUI
import FootballCore

extension MatchEventType {
    /// Tint for the event glyph. Lives in the app target because it depends on
    /// the brand colors in `Theme.swift`; the textual `displayName` /
    /// `symbolName` live in `FootballPresentation`.
    var tint: Color {
        switch self {
        case .yellowCard: Color.yellow
        case .redCard: Color.live
        case .substitution: Color.pitch
        case .videoReview: Color.gray
        }
    }
}
