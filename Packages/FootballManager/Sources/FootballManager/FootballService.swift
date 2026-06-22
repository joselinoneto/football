import FootballCore

/// What the UI layer talks to. Reads come from the local store; `refresh()`
/// pulls from the network and updates the store.
public protocol FootballService: Sendable {
    func refresh() async throws
    /// A focused refresh of just Teams and Matches — enough to show scores,
    /// status, and the match clock. Used by the Home Screen widget, where the
    /// full `refresh()` (ten tables) is too heavy for the timeline budget.
    func refreshScores() async throws
    func teams() async throws -> [Team]
    func matches() async throws -> [Match]
    func goals() async throws -> [Goal]
    func standings() async throws -> [Standing]
    func matchStats() async throws -> [MatchStat]
    func lineups() async throws -> [LineupEntry]
    func topScorers() async throws -> [TopScorer]
    func matchEvents() async throws -> [MatchEvent]
    func squads() async throws -> [SquadMember]
    func venues() async throws -> [Venue]
}
