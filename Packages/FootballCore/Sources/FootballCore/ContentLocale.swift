/// The language the Airtable content is requested in. English is the
/// canonical language; pt-BR content lives in dedicated "* pt-BR" fields.
public enum ContentLocale: String, CaseIterable, Sendable {
    case english = "en"
    case brazilianPortuguese = "pt-BR"

    /// Resolves the content locale from the app's preferred localizations
    /// (e.g. `Bundle.main.preferredLocalizations`).
    public init(preferredLanguages: [String]) {
        let first = preferredLanguages.first?.lowercased() ?? "en"
        self = first.hasPrefix("pt") ? .brazilianPortuguese : .english
    }
}
