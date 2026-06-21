/// A non-goal match event. Raw values match the Airtable `Type` select options
/// in the `Match Events` table; the user-facing label is localized client-side.
public enum MatchEventType: String, CaseIterable, Hashable, Sendable {
    case yellowCard = "Yellow Card"
    case redCard = "Red Card"
    case substitution = "Substitution"
    case videoReview = "VAR"
}

/// A non-goal event in a match (cards, substitutions, VAR), from the Airtable
/// `Match Events` table. Goals live in the separate `Goal` type.
public struct MatchEvent: Identifiable, Hashable, Sendable {
    /// Airtable record ID.
    public let id: String
    /// Official match number this event belongs to (1–104).
    public let matchNumber: Int
    /// Linked Match record ID, when resolved.
    public let matchID: String?
    /// Linked Team record ID the event is credited to.
    public let teamID: String?
    public let type: MatchEventType
    /// The carded player, or — for a substitution — the player going off.
    public let player: String
    /// For substitutions, the player coming on; nil otherwise.
    public let player2: String?
    /// Raw feed detail, e.g. "Yellow Card", "Substitution 2".
    public let detail: String
    /// Match clock, e.g. "80'" or "90+2'".
    public let minute: String

    public init(
        id: String,
        matchNumber: Int,
        matchID: String?,
        teamID: String?,
        type: MatchEventType,
        player: String,
        player2: String?,
        detail: String,
        minute: String
    ) {
        self.id = id
        self.matchNumber = matchNumber
        self.matchID = matchID
        self.teamID = teamID
        self.type = type
        self.player = player
        self.player2 = player2
        self.detail = detail
        self.minute = minute
    }
}
