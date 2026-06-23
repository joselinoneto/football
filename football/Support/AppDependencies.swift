import Foundation
import FootballCore
import FootballAPI
import FootballStorage
import FootballManager

/// App Group shared by the app and the Home Screen widget so they read and
/// write the same SwiftData store. Must match the value in the widget target
/// and both `.entitlements` files.
let footballAppGroupID = "group.app.zeneto.football"

/// Composition root: wires the API, the local store, and the manager.
struct AppDependencies {
    let service: any FootballService

    static func live() -> AppDependencies {
        do {
            let api = AirtableFootballClient(configuration: .current)
            let store = FootballStore(modelContainer: try FootballStore.makeContainer(appGroupID: footballAppGroupID))
            // Bundle.main.preferredLocalizations is the UI language iOS
            // resolved for this app (en or pt-BR), so remote content always
            // matches the interface language.
            let locale = ContentLocale(preferredLanguages: Bundle.main.preferredLocalizations)
            return AppDependencies(service: FootballManager(api: api, store: store, locale: locale))
        } catch {
            fatalError("Could not create the local football store: \(error)")
        }
    }
}
