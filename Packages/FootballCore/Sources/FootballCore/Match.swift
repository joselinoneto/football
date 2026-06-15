import Foundation

public enum Stage: String, CaseIterable, Hashable, Sendable {
    case group = "Group"
    case roundOf32 = "Round of 32"
    case roundOf16 = "Round of 16"
    case quarterFinal = "Quarter-final"
    case semiFinal = "Semi-final"
    case thirdPlace = "Third place"
    case final = "Final"

    public var isKnockout: Bool { self != .group }
}

public enum MatchStatus: String, CaseIterable, Hashable, Sendable {
    case scheduled = "Scheduled"
    case live = "Live"
    case finished = "Finished"
}

public struct Match: Identifiable, Hashable, Sendable {
    /// Airtable record ID.
    public let id: String
    /// Official match number 1–104.
    public let number: Int
    /// Primary field, e.g. "Brazil vs Morocco". Knockout matches may name
    /// placeholders ("Winner Match 74") before the teams are decided.
    public let title: String
    /// Linked Team record IDs; nil until the team is decided.
    public let homeTeamID: String?
    public let awayTeamID: String?
    /// Kickoff in UTC.
    public let kickoff: Date
    public let stage: Stage
    public let venue: String
    public let homeScore: Int?
    public let awayScore: Int?
    public let status: MatchStatus
    /// Live match clock as supplied by the feed, e.g. "67'" or "90+2'".
    /// Present only while `status == .live`; nil otherwise.
    public let minute: String?

    public init(
        id: String,
        number: Int,
        title: String,
        homeTeamID: String?,
        awayTeamID: String?,
        kickoff: Date,
        stage: Stage,
        venue: String,
        homeScore: Int?,
        awayScore: Int?,
        status: MatchStatus,
        minute: String? = nil
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.homeTeamID = homeTeamID
        self.awayTeamID = awayTeamID
        self.kickoff = kickoff
        self.stage = stage
        self.venue = venue
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.status = status
        self.minute = minute
    }

    /// Home/away names parsed from the title, used as a fallback when the
    /// linked teams are not decided yet. Handles both the English ("vs")
    /// and Brazilian ("x") conventions.
    public var titleSides: (home: String, away: String)? {
        for separator in [" vs ", " x "] {
            let parts = title.components(separatedBy: separator)
            if parts.count == 2 {
                return (parts[0], parts[1])
            }
        }
        return nil
    }
}
