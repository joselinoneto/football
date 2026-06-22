import Foundation
import FootballCore
import FootballAPI
import FootballStorage
import FootballManager

/// Composition root for the watch app: wires the API, the local store, and the
/// manager. Mirrors the iOS app's composition root — the data layer is shared
/// through the local packages, only the views differ.
struct AppDependencies {
    let service: any FootballService

    static func live() -> AppDependencies {
        do {
            let api = AirtableFootballClient(configuration: .current)
            let store = FootballStore(modelContainer: try FootballStore.makeContainer())
            // Bundle.main.preferredLocalizations is the UI language watchOS
            // resolved for this app (en or pt-BR), so remote content always
            // matches the interface language.
            let locale = ContentLocale(preferredLanguages: Bundle.main.preferredLocalizations)
            return AppDependencies(service: FootballManager(api: api, store: store, locale: locale))
        } catch {
            fatalError("Could not create the local football store: \(error)")
        }
    }
}
