import Foundation

/// One entry in the tournament's scoring leaderboard, from the Airtable
/// `Top Scorers` table (refreshed as results land).
public struct TopScorer: Identifiable, Hashable, Sendable {
    /// Airtable record ID.
    public let id: String
    /// Rank in the leaderboard (1 = leader).
    public let rank: Int
    /// Player name — a proper noun, never localized.
    public let player: String
    /// Linked Team record ID, when resolved.
    public let teamID: String?
    public let goals: Int
    public let assists: Int
    public let penalties: Int
    public let minutes: Int
    /// Player headshot, when available.
    public let photoURL: URL?

    public init(
        id: String,
        rank: Int,
        player: String,
        teamID: String?,
        goals: Int,
        assists: Int,
        penalties: Int,
        minutes: Int,
        photoURL: URL?
    ) {
        self.id = id
        self.rank = rank
        self.player = player
        self.teamID = teamID
        self.goals = goals
        self.assists = assists
        self.penalties = penalties
        self.minutes = minutes
        self.photoURL = photoURL
    }
}
