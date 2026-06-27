import FootballCore
import FootballAPI
import FootballStorage

public final class FootballManager: FootballService {
    private let api: any FootballAPIClient
    private let store: FootballStore
    private let locale: ContentLocale

    /// `locale` selects which language the remote content is fetched in;
    /// iOS relaunches the app when the user changes language, so it is
    /// fixed for the manager's lifetime.
    public init(api: any FootballAPIClient, store: FootballStore, locale: ContentLocale) {
        self.api = api
        self.store = store
        self.locale = locale
    }

    public func refresh() async throws {
        async let teams = api.fetchTeams(locale: locale)
        async let matches = api.fetchMatches(locale: locale)
        async let goals = api.fetchGoals()
        async let standings = api.fetchStandings()
        async let matchStats = api.fetchMatchStats()
        async let lineups = api.fetchLineups()
        async let topScorers = api.fetchTopScorers()
        async let matchEvents = api.fetchMatchEvents()
        async let squads = api.fetchSquads()
        async let venues = api.fetchVenues()
        try await store.replaceTeams(teams)
        try await store.replaceMatches(matches)
        try await store.replaceGoals(goals)
        try await store.replaceStandings(standings)
        try await store.replaceMatchStats(matchStats)
        try await store.replaceLineups(lineups)
        try await store.replaceTopScorers(topScorers)
        try await store.replaceMatchEvents(matchEvents)
        try await store.replaceSquads(squads)
        try await store.replaceVenues(venues)
    }

    /// Reference data that is stable across a matchday. Loaded once at launch
    /// and on manual pull-to-refresh, never from the polling loop.
    public func refreshStatic() async throws {
        async let teams = api.fetchTeams(locale: locale)
        async let standings = api.fetchStandings()
        async let topScorers = api.fetchTopScorers()
        async let lineups = api.fetchLineups()
        async let squads = api.fetchSquads()
        async let venues = api.fetchVenues()
        try await store.replaceTeams(teams)
        try await store.replaceStandings(standings)
        try await store.replaceTopScorers(topScorers)
        try await store.replaceLineups(lineups)
        try await store.replaceSquads(squads)
        try await store.replaceVenues(venues)
    }

    /// The polling payload — scoped to just the matches that can be changing
    /// right now. Instead of pulling whole tables every cycle, it asks Airtable
    /// for the live/imminent matches, then for only the goals, stats, and events
    /// belonging to those match numbers.
    ///
    /// Standings are deliberately *not* polled here — they refresh when the
    /// Standings section is presented (see `refreshStandings()`). With one live
    /// match this is ~4 single-page requests instead of paging through all ten
    /// tables; with none live it is just the live-matches probe.
    public func refreshLive() async throws {
        // Live/imminent matches only; upsert (never prune) so other days'
        // matches that this scoped fetch omits stay in the store.
        let liveMatches = try await api.fetchLiveMatches(locale: locale)
        try await store.upsertMatches(liveMatches)

        // Their numbers scope both the child-table fetches and the prune, so a
        // goal/event removed from a live match is cleared without touching the
        // rest of the tournament.
        let scope = Set(liveMatches.map(\.number))
        let numbers = Array(scope)

        async let goals = api.fetchGoals(matchNumbers: numbers)
        async let matchStats = api.fetchMatchStats(matchNumbers: numbers)
        async let matchEvents = api.fetchMatchEvents(matchNumbers: numbers)

        try await store.mergeGoals(goals, forMatchNumbers: scope)
        try await store.mergeMatchStats(matchStats, forMatchNumbers: scope)
        try await store.mergeMatchEvents(matchEvents, forMatchNumbers: scope)
    }

    /// Refreshes just the standings table. Called when the Standings section is
    /// presented rather than on the polling loop, so standings stay accurate
    /// without a per-cycle request while matches are live.
    public func refreshStandings() async throws {
        let standings = try await api.fetchStandings()
        try await store.replaceStandings(standings)
    }

    public func refreshScores() async throws {
        async let teams = api.fetchTeams(locale: locale)
        async let matches = api.fetchMatches(locale: locale)
        try await store.replaceTeams(teams)
        try await store.replaceMatches(matches)
    }

    /// Only the live/imminent matches, upserted so the cached full schedule and
    /// team list survive. A single scoped request — the widget uses it for live
    /// ticks once the store is warm.
    public func refreshLiveScores() async throws {
        let liveMatches = try await api.fetchLiveMatches(locale: locale)
        try await store.upsertMatches(liveMatches)
    }

    public func teams() async throws -> [Team] {
        try await store.teams()
    }

    public func matches() async throws -> [Match] {
        try await store.matches()
    }

    public func goals() async throws -> [Goal] {
        try await store.goals()
    }

    public func standings() async throws -> [Standing] {
        try await store.standings()
    }

    public func matchStats() async throws -> [MatchStat] {
        try await store.matchStats()
    }

    public func lineups() async throws -> [LineupEntry] {
        try await store.lineups()
    }

    public func topScorers() async throws -> [TopScorer] {
        try await store.topScorers()
    }

    public func matchEvents() async throws -> [MatchEvent] {
        try await store.matchEvents()
    }

    public func squads() async throws -> [SquadMember] {
        try await store.squads()
    }

    public func venues() async throws -> [Venue] {
        try await store.venues()
    }
}
