/// How a goal was scored. Raw values match the Airtable `Type` select options;
/// the user-facing label is localized client-side (see `GoalType+Display`),
/// the same way `Stage` is.
public enum GoalType: String, CaseIterable, Hashable, Sendable {
    case goal = "Goal"
    case penalty = "Penalty"
    case ownGoal = "Own Goal"
}

/// A single goal in a match, captured live. The Airtable `Goals` table credits
/// the beneficiary team (so own goals already point at the side that scored),
/// which means `teamID` can be compared directly against a match's home/away
/// team to place the goal on the right side.
public struct Goal: Identifiable, Hashable, Sendable {
    /// Airtable record ID.
    public let id: String
    /// Official match number this goal belongs to (1–104).
    public let matchNumber: Int
    /// Linked Match record ID, when resolved.
    public let matchID: String?
    /// Linked Team record ID of the side credited with the goal.
    public let teamID: String?
    /// Scorer's name — a proper noun, never localized.
    public let scorer: String
    /// Match clock, e.g. "23'" or "90+2'".
    public let minute: String
    public let type: GoalType

    public init(
        id: String,
        matchNumber: Int,
        matchID: String?,
        teamID: String?,
        scorer: String,
        minute: String,
        type: GoalType
    ) {
        self.id = id
        self.matchNumber = matchNumber
        self.matchID = matchID
        self.teamID = teamID
        self.scorer = scorer
        self.minute = minute
        self.type = type
    }
}
