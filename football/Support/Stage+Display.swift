import Foundation
import FootballCore

extension Stage {
    /// User-facing, localized stage name. Raw values stay as the Airtable
    /// select options and are never shown directly.
    var displayName: String {
        switch self {
        case .group:
            String(localized: "stage.group", defaultValue: "Group stage")
        case .roundOf32:
            String(localized: "stage.roundOf32", defaultValue: "Round of 32")
        case .roundOf16:
            String(localized: "stage.roundOf16", defaultValue: "Round of 16")
        case .quarterFinal:
            String(localized: "stage.quarterFinal", defaultValue: "Quarter-final")
        case .semiFinal:
            String(localized: "stage.semiFinal", defaultValue: "Semi-final")
        case .thirdPlace:
            String(localized: "stage.thirdPlace", defaultValue: "Third place")
        case .final:
            String(localized: "stage.final", defaultValue: "Final")
        }
    }
}
