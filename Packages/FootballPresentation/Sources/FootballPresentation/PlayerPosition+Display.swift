import Foundation
import FootballCore

extension PlayerPosition {
    /// Full, user-facing, localized position name.
    public var displayName: String {
        switch self {
        case .goalkeeper: String(localized: "position.goalkeeper", defaultValue: "Goalkeeper", bundle: .module)
        case .defender: String(localized: "position.defender", defaultValue: "Defender", bundle: .module)
        case .midfielder: String(localized: "position.midfielder", defaultValue: "Midfielder", bundle: .module)
        case .attacker: String(localized: "position.attacker", defaultValue: "Attacker", bundle: .module)
        }
    }

    /// Sort order goalkeeper → attacker, for grouping a roster by line.
    public var sortOrder: Int {
        switch self {
        case .goalkeeper: 0
        case .defender: 1
        case .midfielder: 2
        case .attacker: 3
        }
    }
}
