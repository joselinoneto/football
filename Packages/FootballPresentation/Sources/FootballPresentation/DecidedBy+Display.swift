import Foundation
import FootballCore

extension DecidedBy {
    /// Full-time status note for the scoreboard, e.g. "After penalties".
    /// Regulation reads as the plain "Full time" — there's nothing to qualify.
    public var fullTimeNote: String {
        switch self {
        case .regulation:
            String(localized: "result.fullTime", defaultValue: "Full time", bundle: .module)
        case .extraTime:
            String(localized: "result.afterExtraTime", defaultValue: "After extra time", bundle: .module)
        case .penalties:
            String(localized: "result.afterPenalties", defaultValue: "After penalties", bundle: .module)
        }
    }

    /// Compact badge for tight layouts (rows, widgets, watch). Empty for a
    /// regulation result, where the plain score already tells the whole story.
    public var shortLabel: String {
        switch self {
        case .regulation:
            ""
        case .extraTime:
            String(localized: "result.short.extraTime", defaultValue: "AET", bundle: .module)
        case .penalties:
            String(localized: "result.short.penalties", defaultValue: "pens", bundle: .module)
        }
    }
}
