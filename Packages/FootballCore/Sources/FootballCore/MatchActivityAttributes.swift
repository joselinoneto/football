#if os(iOS)
import ActivityKit
import Foundation

/// Live Activity payload for a single in-progress match. The static fields
/// (teams, stage, venue) never change for the life of the activity; the
/// `ContentState` carries the values that tick over — score and match clock —
/// and is what the app pushes on every update.
///
/// Scores/status are kept as plain `Int?`/`String` so the type stays trivially
/// `Codable`; `status` resolves the raw value back to `MatchStatus`.
public struct MatchActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var homeScore: Int?
        public var awayScore: Int?
        /// Live match clock as supplied by the feed, e.g. "67'" or "90+2'".
        public var minute: String?
        public var statusRawValue: String

        public init(homeScore: Int?, awayScore: Int?, minute: String?, status: MatchStatus) {
            self.homeScore = homeScore
            self.awayScore = awayScore
            self.minute = minute
            self.statusRawValue = status.rawValue
        }

        public var status: MatchStatus { MatchStatus(rawValue: statusRawValue) ?? .live }
    }

    /// Airtable record ID of the match — also the deep-link target.
    public let matchID: String
    public let homeFlag: String
    public let homeCode: String
    public let awayFlag: String
    public let awayCode: String
    public let stageRawValue: String
    public let venue: String

    public init(
        matchID: String,
        homeFlag: String,
        homeCode: String,
        awayFlag: String,
        awayCode: String,
        stage: Stage,
        venue: String
    ) {
        self.matchID = matchID
        self.homeFlag = homeFlag
        self.homeCode = homeCode
        self.awayFlag = awayFlag
        self.awayCode = awayCode
        self.stageRawValue = stage.rawValue
        self.venue = venue
    }

    public var stage: Stage { Stage(rawValue: stageRawValue) ?? .group }
}
#endif
