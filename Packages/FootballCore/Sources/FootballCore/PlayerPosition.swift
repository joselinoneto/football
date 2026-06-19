/// A player's position on the pitch. Raw values match the Airtable `Position`
/// text used in both the `Lineups` and `Squads` tables; the user-facing label
/// is localized client-side (the same way `Stage` and `GoalType` are).
public enum PlayerPosition: String, CaseIterable, Hashable, Sendable {
    case goalkeeper = "Goalkeeper"
    case defender = "Defender"
    case midfielder = "Midfielder"
    case attacker = "Attacker"
}
