import Foundation
import FootballCore

public protocol FootballAPIClient: Sendable {
    func fetchTeams(locale: ContentLocale) async throws -> [Team]
    func fetchMatches(locale: ContentLocale) async throws -> [Match]
    func fetchGoals() async throws -> [Goal]
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
}
