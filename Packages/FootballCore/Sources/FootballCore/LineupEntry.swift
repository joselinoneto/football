/// One player's appearance in a match, from the Airtable `Lineups` table: the
/// formation slot merged with the player's match stats (rating, minutes).
public struct LineupEntry: Identifiable, Hashable, Sendable {
    /// Airtable record ID.
    public let id: String
    /// Official match number this appearance belongs to (1–104).
    public let matchNumber: Int
    /// Linked Match record ID, when resolved.
    public let matchID: String?
    /// Linked Team record ID the player lined up for.
    public let teamID: String?
    /// Player name — a proper noun, never localized.
    public let player: String
    /// Shirt number.
    public let number: Int?
    /// Position; nil when the feed reports an unrecognized slot.
    public let position: PlayerPosition?
    /// Pitch grid coordinates, e.g. "2:4"; nil for substitutes.
    public let grid: String?
    /// Whether the player was in the starting XI (vs. on the bench).
    public let started: Bool
    public let captain: Bool
    /// Match rating, e.g. 8.2; nil when not rated.
    public let rating: Double?
    public let minutes: Int?
    public let goals: Int
    public let assists: Int

    public init(
        id: String,
        matchNumber: Int,
        matchID: String?,
        teamID: String?,
        player: String,
        number: Int?,
        position: PlayerPosition?,
        grid: String?,
        started: Bool,
        captain: Bool,
        rating: Double?,
        minutes: Int?,
        goals: Int,
        assists: Int
    ) {
        self.id = id
        self.matchNumber = matchNumber
        self.matchID = matchID
        self.teamID = teamID
        self.player = player
        self.number = number
        self.position = position
        self.grid = grid
        self.started = started
        self.captain = captain
        self.rating = rating
        self.minutes = minutes
        self.goals = goals
        self.assists = assists
    }
}
