import Foundation

/// The `justfootball://match/<recordID>` URL the widget and Live Activity open,
/// and that the app parses to jump straight to a match. Defined once here so the
/// producer (widget) and the consumer (app) can never drift apart.
public enum MatchDeepLink {
    public static let scheme = "justfootball"

    public static func url(matchID: String) -> URL {
        URL(string: "\(scheme)://match/\(matchID)")!
    }

    /// The match record ID encoded in `url`, or nil if it isn't one of ours.
    public static func matchID(from url: URL) -> String? {
        guard url.scheme == scheme, url.host == "match" else { return nil }
        let id = url.lastPathComponent
        return id.isEmpty || id == "/" ? nil : id
    }
}
