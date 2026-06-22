import Foundation
import FootballCore
import FootballAPI
import FootballStorage
import FootballManager

/// App Group shared with the main app. Must match `footballAppGroupID` in the
/// app target and both `.entitlements` files.
let widgetAppGroupID = "group.app.zeneto.football"

/// Composition root for the widget process: the Airtable client, the shared
/// App Group store (written by the app, read — and lightly refreshed — here),
/// and the manager that ties them together. Built once and reused across
/// timeline reloads.
enum WidgetDependencies {
    static let service: any FootballService = {
        let api = AirtableFootballClient(configuration: .current)
        let store: FootballStore
        do {
            store = FootballStore(modelContainer: try FootballStore.makeContainer(appGroupID: widgetAppGroupID))
        } catch {
            fatalError("Could not open the shared football store: \(error)")
        }
        let locale = ContentLocale(preferredLanguages: Bundle.main.preferredLocalizations)
        return FootballManager(api: api, store: store, locale: locale)
    }()
}
