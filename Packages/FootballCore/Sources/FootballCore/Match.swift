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

/// How a finished match was settled. Knockout ties can go beyond 90 minutes;
/// group matches are always `.regulation`. Raw values match the Airtable
/// "Decided By" select; display text is localized client-side.
public enum DecidedBy: String, CaseIterable, Hashable, Sendable {
    case regulation = "Regulation"
    case extraTime = "Extra Time"
    case penalties = "Penalties"
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
    /// Penalty-shootout scores; non-nil only for a knockout tie settled on
    /// penalties (the after-extra-time score stays in `homeScore`/`awayScore`).
    public let homePenalties: Int?
    public let awayPenalties: Int?
    public let status: MatchStatus
    /// Live match clock as supplied by the feed, e.g. "67'" or "90+2'".
    /// Present only while `status == .live`; nil otherwise.
    public let minute: String?
    /// Linked Team record ID of the winner; nil for a regulation draw (group
    /// stage) or a match that isn't finished. The reliable way to know who
    /// advanced when the scoreline is level after a shootout.
    public let winnerTeamID: String?
    /// How the result was settled; nil until the match is finished.
    public let decidedBy: DecidedBy?

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
        minute: String? = nil,
        homePenalties: Int? = nil,
        awayPenalties: Int? = nil,
        winnerTeamID: String? = nil,
        decidedBy: DecidedBy? = nil
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
        self.homePenalties = homePenalties
        self.awayPenalties = awayPenalties
        self.winnerTeamID = winnerTeamID
        self.decidedBy = decidedBy
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
