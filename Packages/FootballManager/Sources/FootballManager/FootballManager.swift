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
