import Foundation

/// A member of a team's squad, from the Airtable `Squads` table. This is static
/// reference data (loaded separately from live match data), so unlike a
/// `LineupEntry` it carries no per-match stats.
public struct SquadMember: Identifiable, Hashable, Sendable {
    /// Airtable record ID.
    public let id: String
    /// Linked Team record ID, when resolved.
    public let teamID: String?
    /// Player name — a proper noun, never localized.
    public let player: String
    /// Shirt number.
    public let number: Int?
    /// Position; nil when the feed reports an unrecognized slot.
    public let position: PlayerPosition?
    public let age: Int?
    /// Player headshot, when available.
    public let photoURL: URL?

    public init(
        id: String,
        teamID: String?,
        player: String,
        number: Int?,
        position: PlayerPosition?,
        age: Int?,
        photoURL: URL?
    ) {
        self.id = id
        self.teamID = teamID
        self.player = player
        self.number = number
        self.position = position
        self.age = age
        self.photoURL = photoURL
    }
}
