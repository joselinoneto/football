import Foundation

/// Persists the user's favorite-team brand color in the shared App Group so the
/// app, the Home Screen widget, and the Live Activity all read the same value.
/// The expensive flag-color extraction runs once (in the app, on selection); only
/// the resolved RGB is stored here, so every reader — including `Color.pitch` —
/// stays cheap.
public enum BrandColorStore {
    /// A plain RGB triple in the sRGB 0...1 range, persisted as "r,g,b".
    public struct RGB: Equatable, Sendable {
        public let red, green, blue: Double
        public init(red: Double, green: Double, blue: Double) {
            self.red = red; self.green = green; self.blue = blue
        }
    }

    public struct Stored: Equatable, Sendable {
        public let teamID: String
        public let light: RGB
        public let dark: RGB
    }

    /// Must match the App Group in the entitlements and
    /// `AppDependencies`/`WidgetDependencies`.
    private static let suiteName = "group.app.zeneto.football"
    private static let teamKey = "favoriteTeamID"
    private static let lightKey = "brandColorLight"
    private static let darkKey = "brandColorDark"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: suiteName) }

    public static var favoriteTeamID: String? { defaults?.string(forKey: teamKey) }

    public static func current() -> Stored? {
        guard let defaults,
              let teamID = defaults.string(forKey: teamKey),
              let light = rgb(defaults.string(forKey: lightKey)),
              let dark = rgb(defaults.string(forKey: darkKey))
        else { return nil }
        return Stored(teamID: teamID, light: light, dark: dark)
    }

    public static func save(teamID: String, light: RGB, dark: RGB) {
        guard let defaults else { return }
        defaults.set(teamID, forKey: teamKey)
        defaults.set(string(light), forKey: lightKey)
        defaults.set(string(dark), forKey: darkKey)
    }

    public static func clear() {
        guard let defaults else { return }
        defaults.removeObject(forKey: teamKey)
        defaults.removeObject(forKey: lightKey)
        defaults.removeObject(forKey: darkKey)
    }

    private static func string(_ c: RGB) -> String { "\(c.red),\(c.green),\(c.blue)" }

    private static func rgb(_ string: String?) -> RGB? {
        guard let parts = string?.split(separator: ","), parts.count == 3,
              let r = Double(parts[0]), let g = Double(parts[1]), let b = Double(parts[2])
        else { return nil }
        return RGB(red: r, green: g, blue: b)
    }
}
