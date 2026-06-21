/// One row of a group table. Backed by the Airtable `Standings` table, which
/// API-Football refreshes as results land. `group` is normally a group letter
/// label ("Group A"…"Group L"), but also carries the special "Group Stage"
/// pseudo-group: the ranking of third-placed teams that decides which of them
/// advance.
public struct Standing: Identifiable, Hashable, Sendable {
    /// Airtable record ID.
    public let id: String
    /// "Group A"…"Group L", or "Group Stage" for the best-third ranking.
    public let group: String
    /// Position within the group (1 = top).
    public let rank: Int
    /// Linked Team record ID, when resolved.
    public let teamID: String?
    public let played: Int
    public let win: Int
    public let draw: Int
    public let loss: Int
    public let goalsFor: Int
    public let goalsAgainst: Int
    public let goalDifference: Int
    public let points: Int
    /// Recent results, most recent last, e.g. "WWD".
    public let form: String
    /// Qualification note, e.g. "Round of 32"; nil when the team is not (yet)
    /// qualifying. Localized client-side.
    public let qualification: String?

    public init(
        id: String,
        group: String,
        rank: Int,
        teamID: String?,
        played: Int,
        win: Int,
        draw: Int,
        loss: Int,
        goalsFor: Int,
        goalsAgainst: Int,
        goalDifference: Int,
        points: Int,
        form: String,
        qualification: String?
    ) {
        self.id = id
        self.group = group
        self.rank = rank
        self.teamID = teamID
        self.played = played
        self.win = win
        self.draw = draw
        self.loss = loss
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
        self.goalDifference = goalDifference
        self.points = points
        self.form = form
        self.qualification = qualification
    }
}
