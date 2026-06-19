/// Per-team statistics for a played match, from the Airtable `Match Stats`
/// table. There is one row per side. Values are locale-neutral, so there are
/// no localized variants. Most fields are optional because API-Football does
/// not always report every statistic (xG in particular).
public struct MatchStat: Identifiable, Hashable, Sendable {
    /// Airtable record ID.
    public let id: String
    /// Official match number this row belongs to (1–104).
    public let matchNumber: Int
    /// Linked Match record ID, when resolved.
    public let matchID: String?
    /// Linked Team record ID this row describes.
    public let teamID: String?
    /// Ball possession, kept as supplied, e.g. "62%".
    public let possession: String?
    public let shotsTotal: Int?
    public let shotsOnGoal: Int?
    public let shotsOffGoal: Int?
    public let blockedShots: Int?
    public let shotsInsideBox: Int?
    public let shotsOutsideBox: Int?
    public let corners: Int?
    public let offsides: Int?
    public let fouls: Int?
    public let yellowCards: Int?
    public let redCards: Int?
    public let saves: Int?
    public let passesTotal: Int?
    public let passesAccurate: Int?
    /// Passing accuracy, kept as supplied, e.g. "88%".
    public let passesPercent: String?
    /// Expected goals (xG); nil when the feed omits it.
    public let expectedGoals: Double?

    public init(
        id: String,
        matchNumber: Int,
        matchID: String?,
        teamID: String?,
        possession: String?,
        shotsTotal: Int?,
        shotsOnGoal: Int?,
        shotsOffGoal: Int?,
        blockedShots: Int?,
        shotsInsideBox: Int?,
        shotsOutsideBox: Int?,
        corners: Int?,
        offsides: Int?,
        fouls: Int?,
        yellowCards: Int?,
        redCards: Int?,
        saves: Int?,
        passesTotal: Int?,
        passesAccurate: Int?,
        passesPercent: String?,
        expectedGoals: Double?
    ) {
        self.id = id
        self.matchNumber = matchNumber
        self.matchID = matchID
        self.teamID = teamID
        self.possession = possession
        self.shotsTotal = shotsTotal
        self.shotsOnGoal = shotsOnGoal
        self.shotsOffGoal = shotsOffGoal
        self.blockedShots = blockedShots
        self.shotsInsideBox = shotsInsideBox
        self.shotsOutsideBox = shotsOutsideBox
        self.corners = corners
        self.offsides = offsides
        self.fouls = fouls
        self.yellowCards = yellowCards
        self.redCards = redCards
        self.saves = saves
        self.passesTotal = passesTotal
        self.passesAccurate = passesAccurate
        self.passesPercent = passesPercent
        self.expectedGoals = expectedGoals
    }
}
