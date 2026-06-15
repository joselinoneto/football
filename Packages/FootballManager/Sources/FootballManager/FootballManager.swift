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
        try await store.replaceTeams(teams)
        try await store.replaceMatches(matches)
        try await store.replaceGoals(goals)
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
}
