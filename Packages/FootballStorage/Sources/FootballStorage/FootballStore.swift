import Foundation
import SwiftData
import FootballCore

/// Local copy of the tournament data. All access goes through this actor;
/// callers exchange `FootballCore` value types only, so SwiftData models
/// never cross an isolation boundary.
@ModelActor
public actor FootballStore {
    /// Builds the local store. Pass `appGroupID` to place the store in a shared
    /// App Group container so another process — the Home Screen widget — can read
    /// the same data the app writes. When `nil` (the default, used by the Watch
    /// app) the store lives in the target's own Application Support directory.
    public static func makeContainer(inMemory: Bool = false, appGroupID: String? = nil) throws -> ModelContainer {
        let schema = Schema([
            StoredTeam.self, StoredMatch.self, StoredGoal.self,
            StoredStanding.self, StoredMatchStat.self, StoredLineupEntry.self,
            StoredTopScorer.self, StoredMatchEvent.self, StoredSquadMember.self,
            StoredVenue.self,
        ])
        let configuration: ModelConfiguration
        if let appGroupID {
            configuration = ModelConfiguration(
                "Football",
                schema: schema,
                groupContainer: .identifier(appGroupID)
            )
        } else {
            configuration = ModelConfiguration("Football", schema: schema, isStoredInMemoryOnly: inMemory)
        }
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

    public func goals() throws -> [Goal] {
        let descriptor = FetchDescriptor<StoredGoal>(
            sortBy: [SortDescriptor(\.matchNumber)]
        )
        return try modelContext.fetch(descriptor).map(\.goal)
    }

    public func standings() throws -> [Standing] {
        let descriptor = FetchDescriptor<StoredStanding>(
            sortBy: [SortDescriptor(\.groupName), SortDescriptor(\.rank)]
        )
        return try modelContext.fetch(descriptor).map(\.standing)
    }

    public func matchStats() throws -> [MatchStat] {
        let descriptor = FetchDescriptor<StoredMatchStat>(
            sortBy: [SortDescriptor(\.matchNumber)]
        )
        return try modelContext.fetch(descriptor).map(\.matchStat)
    }

    public func lineups() throws -> [LineupEntry] {
        let descriptor = FetchDescriptor<StoredLineupEntry>(
            sortBy: [SortDescriptor(\.matchNumber), SortDescriptor(\.player)]
        )
        return try modelContext.fetch(descriptor).map(\.lineupEntry)
    }

    public func topScorers() throws -> [TopScorer] {
        let descriptor = FetchDescriptor<StoredTopScorer>(
            sortBy: [SortDescriptor(\.rank)]
        )
        return try modelContext.fetch(descriptor).map(\.topScorer)
    }

    public func matchEvents() throws -> [MatchEvent] {
        let descriptor = FetchDescriptor<StoredMatchEvent>(
            sortBy: [SortDescriptor(\.matchNumber)]
        )
        return try modelContext.fetch(descriptor).map(\.matchEvent)
    }

    public func squads() throws -> [SquadMember] {
        let descriptor = FetchDescriptor<StoredSquadMember>(
            sortBy: [SortDescriptor(\.player)]
        )
        return try modelContext.fetch(descriptor).map(\.squadMember)
    }

    public func venues() throws -> [Venue] {
        let descriptor = FetchDescriptor<StoredVenue>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor).map(\.venue)
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

    public func replaceGoals(_ goals: [Goal]) throws {
        let stored = try modelContext.fetch(FetchDescriptor<StoredGoal>())
        var existing = Dictionary(stored.map { ($0.remoteID, $0) }, uniquingKeysWith: { first, _ in first })
        for goal in goals {
            if let storedGoal = existing.removeValue(forKey: goal.id) {
                storedGoal.update(from: goal)
            } else {
                modelContext.insert(StoredGoal(goal))
            }
        }
        existing.values.forEach(modelContext.delete)
        try modelContext.save()
    }

    /// Generic upsert-by-remote-ID + prune, mirroring `replaceTeams` et al.:
    /// updates rows that still exist, inserts new ones, deletes the rest, so
    /// the local table mirrors the remote one.
    private func reconcile<Stored: PersistentModel, Value>(
        _ values: [Value],
        id: (Value) -> String,
        storedID: (Stored) -> String,
        insert: (Value) -> Stored,
        update: (Stored, Value) -> Void
    ) throws {
        let stored = try modelContext.fetch(FetchDescriptor<Stored>())
        var existing = Dictionary(stored.map { (storedID($0), $0) }, uniquingKeysWith: { first, _ in first })
        for value in values {
            if let row = existing.removeValue(forKey: id(value)) {
                update(row, value)
            } else {
                modelContext.insert(insert(value))
            }
        }
        existing.values.forEach(modelContext.delete)
        try modelContext.save()
    }

    public func replaceStandings(_ items: [Standing]) throws {
        try reconcile(items, id: \.id, storedID: \StoredStanding.remoteID,
                      insert: StoredStanding.init, update: { $0.update(from: $1) })
    }

    public func replaceMatchStats(_ items: [MatchStat]) throws {
        try reconcile(items, id: \.id, storedID: \StoredMatchStat.remoteID,
                      insert: StoredMatchStat.init, update: { $0.update(from: $1) })
    }

    public func replaceLineups(_ items: [LineupEntry]) throws {
        try reconcile(items, id: \.id, storedID: \StoredLineupEntry.remoteID,
                      insert: StoredLineupEntry.init, update: { $0.update(from: $1) })
    }

    public func replaceTopScorers(_ items: [TopScorer]) throws {
        try reconcile(items, id: \.id, storedID: \StoredTopScorer.remoteID,
                      insert: StoredTopScorer.init, update: { $0.update(from: $1) })
    }

    public func replaceMatchEvents(_ items: [MatchEvent]) throws {
        try reconcile(items, id: \.id, storedID: \StoredMatchEvent.remoteID,
                      insert: StoredMatchEvent.init, update: { $0.update(from: $1) })
    }

    public func replaceSquads(_ items: [SquadMember]) throws {
        try reconcile(items, id: \.id, storedID: \StoredSquadMember.remoteID,
                      insert: StoredSquadMember.init, update: { $0.update(from: $1) })
    }

    public func replaceVenues(_ items: [Venue]) throws {
        try reconcile(items, id: \.id, storedID: \StoredVenue.remoteID,
                      insert: StoredVenue.init, update: { $0.update(from: $1) })
    }
}
