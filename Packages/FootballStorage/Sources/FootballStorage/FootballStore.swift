import Foundation
import SwiftData
import FootballCore

/// Local copy of the tournament data. All access goes through this actor;
/// callers exchange `FootballCore` value types only, so SwiftData models
/// never cross an isolation boundary.
@ModelActor
public actor FootballStore {
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([StoredTeam.self, StoredMatch.self])
        let configuration = ModelConfiguration("Football", schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: Reads

    public func teams() throws -> [Team] {
        let descriptor = FetchDescriptor<StoredTeam>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor).map(\.team)
    }

    public func matches() throws -> [Match] {
        let descriptor = FetchDescriptor<StoredMatch>(
            sortBy: [SortDescriptor(\.kickoff), SortDescriptor(\.number)]
        )
        return try modelContext.fetch(descriptor).map(\.match)
    }

    // MARK: Writes

    /// Upserts the given teams by record ID and removes any stored team that
    /// is no longer present, so the local copy mirrors the remote table.
    public func replaceTeams(_ teams: [Team]) throws {
        let stored = try modelContext.fetch(FetchDescriptor<StoredTeam>())
        var existing = Dictionary(stored.map { ($0.remoteID, $0) }, uniquingKeysWith: { first, _ in first })
        for team in teams {
            if let storedTeam = existing.removeValue(forKey: team.id) {
                storedTeam.update(from: team)
            } else {
                modelContext.insert(StoredTeam(team))
            }
        }
        existing.values.forEach(modelContext.delete)
        try modelContext.save()
    }

    public func replaceMatches(_ matches: [Match]) throws {
        let stored = try modelContext.fetch(FetchDescriptor<StoredMatch>())
        var existing = Dictionary(stored.map { ($0.remoteID, $0) }, uniquingKeysWith: { first, _ in first })
        for match in matches {
            if let storedMatch = existing.removeValue(forKey: match.id) {
                storedMatch.update(from: match)
            } else {
                modelContext.insert(StoredMatch(match))
            }
        }
        existing.values.forEach(modelContext.delete)
        try modelContext.save()
    }
}
