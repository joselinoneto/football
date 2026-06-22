import Foundation
import FootballCore

extension Stage {
    /// User-facing, localized stage name. Raw values stay as the Airtable
    /// select options and are never shown directly.
    public var displayName: String {
        switch self {
        case .group:
            String(localized: "stage.group", defaultValue: "Group stage", bundle: .module)
        case .roundOf32:
            String(localized: "stage.roundOf32", defaultValue: "Round of 32", bundle: .module)
        case .roundOf16:
            String(localized: "stage.roundOf16", defaultValue: "Round of 16", bundle: .module)
        case .quarterFinal:
            String(localized: "stage.quarterFinal", defaultValue: "Quarter-final", bundle: .module)
        case .semiFinal:
            String(localized: "stage.semiFinal", defaultValue: "Semi-final", bundle: .module)
        case .thirdPlace:
            String(localized: "stage.thirdPlace", defaultValue: "Third place", bundle: .module)
        case .final:
            String(localized: "stage.final", defaultValue: "Final", bundle: .module)
        }
    }
}
