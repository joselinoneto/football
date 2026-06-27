import FootballCore

/// What the UI layer talks to. Reads come from the local store; `refresh()`
/// pulls from the network and updates the store.
public protocol FootballService: Sendable {
    func refresh() async throws
    /// Reference data that does not change during a matchday: Teams, Standings,
    /// Top Scorers, Lineups, Squads, Venues. Fetched once at launch and on
    /// manual pull-to-refresh — kept out of the polling loop to spare the API.
    func refreshStatic() async throws
    /// The tables that change while a match is in play: Matches, Goals, Match
    /// Stats, Match Events. This is what the adaptive polling loop pulls, so the
    /// per-poll request count stays small instead of fetching all ten tables.
    func refreshLive() async throws
    /// A focused refresh of just Teams and Matches — enough to show scores,
    /// status, and the match clock. Used by the Home Screen widget on a cold
    /// store, where the full `refresh()` (ten tables) is too heavy for the
    /// timeline budget.
    func refreshScores() async throws
    /// The leanest refresh: only the live/imminent matches, upserted (no Teams,
    /// no pruning). For the widget's frequent live ticks, where the full
    /// schedule and team list are already cached in the shared store.
    func refreshLiveScores() async throws
    /// Refreshes just the standings table. Driven by the Standings section
    /// appearing rather than the polling loop, so standings stay current without
    /// a per-cycle request during live matches.
    func refreshStandings() async throws
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
