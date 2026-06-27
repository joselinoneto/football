import Foundation
import FootballCore

public protocol FootballAPIClient: Sendable {
    func fetchTeams(locale: ContentLocale) async throws -> [Team]
    func fetchMatches(locale: ContentLocale) async throws -> [Match]
    func fetchGoals() async throws -> [Goal]
    func fetchStandings() async throws -> [Standing]
    func fetchMatchStats() async throws -> [MatchStat]
    func fetchLineups() async throws -> [LineupEntry]
    func fetchTopScorers() async throws -> [TopScorer]
    func fetchMatchEvents() async throws -> [MatchEvent]
    func fetchSquads() async throws -> [SquadMember]
    func fetchVenues() async throws -> [Venue]

    // Scoped variants for the live polling loop: instead of pulling whole
    // tables, they ask Airtable for just the live/imminent matches and the
    // child rows (goals, stats, events) belonging to those match numbers.
    func fetchLiveMatches(locale: ContentLocale) async throws -> [Match]
    func fetchGoals(matchNumbers: [Int]) async throws -> [Goal]
    func fetchMatchStats(matchNumbers: [Int]) async throws -> [MatchStat]
    func fetchMatchEvents(matchNumbers: [Int]) async throws -> [MatchEvent]
}

public struct AirtableFootballClient: FootballAPIClient {
    private let transport: AirtableTransport

    public init(configuration: AirtableConfiguration, session: URLSession = .shared) {
        self.transport = AirtableTransport(configuration: configuration, session: session)
    }

    public func fetchTeams(locale: ContentLocale) async throws -> [Team] {
        let records: [AirtableRecord<TeamFields>] = try await transport.allRecords(
            table: "Teams",
            fields: TeamFields.requestedFields(for: locale)
        )
        return records.compactMap { Team(record: $0, locale: locale) }
    }

    public func fetchMatches(locale: ContentLocale) async throws -> [Match] {
        let records: [AirtableRecord<MatchFields>] = try await transport.allRecords(
            table: "Matches",
            fields: MatchFields.requestedFields(for: locale)
        )
        return records.compactMap { Match(record: $0, locale: locale) }
            .sorted { $0.number < $1.number }
    }

    public func fetchGoals() async throws -> [Goal] {
        let records: [AirtableRecord<GoalFields>] = try await transport.allRecords(
            table: "Goals",
            fields: GoalFields.requestedFields()
        )
        return records.compactMap { Goal(record: $0) }
    }

    public func fetchStandings() async throws -> [Standing] {
        let records: [AirtableRecord<StandingFields>] = try await transport.allRecords(
            table: "Standings",
            fields: StandingFields.requestedFields()
        )
        return records.compactMap { Standing(record: $0) }
            .sorted { ($0.group, $0.rank) < ($1.group, $1.rank) }
    }

    public func fetchMatchStats() async throws -> [MatchStat] {
        let records: [AirtableRecord<MatchStatFields>] = try await transport.allRecords(
            table: "Match Stats",
            fields: MatchStatFields.requestedFields()
        )
        return records.compactMap { MatchStat(record: $0) }
    }

    public func fetchLineups() async throws -> [LineupEntry] {
        let records: [AirtableRecord<LineupFields>] = try await transport.allRecords(
            table: "Lineups",
            fields: LineupFields.requestedFields()
        )
        return records.compactMap { LineupEntry(record: $0) }
    }

    public func fetchTopScorers() async throws -> [TopScorer] {
        let records: [AirtableRecord<TopScorerFields>] = try await transport.allRecords(
            table: "Top Scorers",
            fields: TopScorerFields.requestedFields()
        )
        return records.compactMap { TopScorer(record: $0) }
            .sorted { $0.rank < $1.rank }
    }

    public func fetchMatchEvents() async throws -> [MatchEvent] {
        let records: [AirtableRecord<MatchEventFields>] = try await transport.allRecords(
            table: "Match Events",
            fields: MatchEventFields.requestedFields()
        )
        return records.compactMap { MatchEvent(record: $0) }
    }

    public func fetchSquads() async throws -> [SquadMember] {
        let records: [AirtableRecord<SquadFields>] = try await transport.allRecords(
            table: "Squads",
            fields: SquadFields.requestedFields()
        )
        return records.compactMap { SquadMember(record: $0) }
    }

    public func fetchVenues() async throws -> [Venue] {
        let records: [AirtableRecord<VenueFields>] = try await transport.allRecords(
            table: "Venues",
            fields: VenueFields.requestedFields()
        )
        return records.compactMap { Venue(record: $0) }
    }

    // MARK: - Scoped (live polling)

    public func fetchLiveMatches(locale: ContentLocale) async throws -> [Match] {
        let records: [AirtableRecord<MatchFields>] = try await transport.allRecords(
            table: "Matches",
            fields: MatchFields.requestedFields(for: locale),
            filterByFormula: Self.liveMatchesFormula
        )
        return records.compactMap { Match(record: $0, locale: locale) }
            .sorted { $0.number < $1.number }
    }

    public func fetchGoals(matchNumbers: [Int]) async throws -> [Goal] {
        guard let formula = Self.matchNumberFormula(matchNumbers) else { return [] }
        let records: [AirtableRecord<GoalFields>] = try await transport.allRecords(
            table: "Goals",
            fields: GoalFields.requestedFields(),
            filterByFormula: formula
        )
        return records.compactMap { Goal(record: $0) }
    }

    public func fetchMatchStats(matchNumbers: [Int]) async throws -> [MatchStat] {
        guard let formula = Self.matchNumberFormula(matchNumbers) else { return [] }
        let records: [AirtableRecord<MatchStatFields>] = try await transport.allRecords(
            table: "Match Stats",
            fields: MatchStatFields.requestedFields(),
            filterByFormula: formula
        )
        return records.compactMap { MatchStat(record: $0) }
    }

    public func fetchMatchEvents(matchNumbers: [Int]) async throws -> [MatchEvent] {
        guard let formula = Self.matchNumberFormula(matchNumbers) else { return [] }
        let records: [AirtableRecord<MatchEventFields>] = try await transport.allRecords(
            table: "Match Events",
            fields: MatchEventFields.requestedFields(),
            filterByFormula: formula
        )
        return records.compactMap { MatchEvent(record: $0) }
    }

    /// Matches that are live now, plus any kicking off within a window around
    /// now, so a scheduled match flipping to live — or one that just finished —
    /// is still caught by the scoped poll.
    private static let liveMatchesFormula =
        "OR(LOWER({Status})='live'," +
        "AND(IS_AFTER({Kickoff},DATEADD(NOW(),-3,'hours'))," +
        "IS_BEFORE({Kickoff},DATEADD(NOW(),15,'minutes'))))"

    /// `OR({Match No}=1,{Match No}=2,…)`, or nil when the scope is empty so the
    /// caller can skip the request entirely (an empty `OR()` is invalid).
    private static func matchNumberFormula(_ numbers: [Int]) -> String? {
        guard !numbers.isEmpty else { return nil }
        let clauses = numbers.map { "{Match No}=\($0)" }.joined(separator: ",")
        return "OR(\(clauses))"
    }
}
