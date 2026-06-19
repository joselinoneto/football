import Foundation
import FootballCore

extension PlayerPosition {
    /// Full, user-facing, localized position name.
    var displayName: String {
        switch self {
        case .goalkeeper: String(localized: "position.goalkeeper", defaultValue: "Goalkeeper")
        case .defender: String(localized: "position.defender", defaultValue: "Defender")
        case .midfielder: String(localized: "position.midfielder", defaultValue: "Midfielder")
        case .attacker: String(localized: "position.attacker", defaultValue: "Attacker")
        }
    }

    /// Short tag shown in compact rows, e.g. "GK".
    var shortCode: String {
        switch self {
        case .goalkeeper: String(localized: "position.short.goalkeeper", defaultValue: "GK")
        case .defender: String(localized: "position.short.defender", defaultValue: "DF")
        case .midfielder: String(localized: "position.short.midfielder", defaultValue: "MF")
        case .attacker: String(localized: "position.short.attacker", defaultValue: "FW")
        }
    }

    /// Sort order goalkeeper → attacker, for grouping a roster by line.
    var sortOrder: Int {
        switch self {
        case .goalkeeper: 0
        case .defender: 1
        case .midfielder: 2
        case .attacker: 3
        }
    }
}
