import Foundation
import Observation
import FootballCore
import FootballManager

@MainActor
@Observable
final class StandingsViewModel {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    private(set) var phase: Phase = .loading
    private(set) var groups: [StandingsGroup] = []

    private let service: any FootballService

    init(service: any FootballService) {
        self.service = service
    }

    /// Shows the cached tables immediately, pulls once, then re-reads the local
    /// store on a relaxed cadence — the schedule tab's loop keeps the store
    /// fresh, so this only needs to reflect it, not re-fetch the network.
    func start() async {
        await loadFromStore()
        await refresh()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(60))
            await loadFromStore()
        }
    }

    func refresh() async {
        do {
            try await service.refresh()
            await loadFromStore()
        } catch {
            if groups.isEmpty { phase = .failed(Self.failureMessage) }
        }
    }

    private func loadFromStore() async {
        do {
            async let standingsTask = service.standings()
            async let teamsTask = service.teams()
            let (standings, teams) = try await (standingsTask, teamsTask)
            groups = Self.build(standings, teams: teams)
            if !groups.isEmpty { phase = .loaded }
        } catch {
            if groups.isEmpty { phase = .failed(Self.failureMessage) }
        }
    }

    private static var failureMessage: String {
        String(localized: "Could not load the standings. Check your connection and try again.")
    }

    private static func build(_ standings: [Standing], teams: [Team]) -> [StandingsGroup] {
        let teamsByID = Dictionary(teams.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return Dictionary(grouping: standings, by: \.group)
            .map { name, rows in
                StandingsGroup(
                    name: name,
                    rows: rows.sorted { $0.rank < $1.rank }
                        .map { StandingRowModel(standing: $0, team: $0.teamID.flatMap { teamsByID[$0] }) }
                )
            }
            .sorted { $0.sortKey < $1.sortKey }
    }
}

struct StandingsGroup: Identifiable {
    let name: String
    let rows: [StandingRowModel]

    var id: String { name }

    /// The pooled third-placed ranking sorts last and is labelled differently.
    var isThirdPlaceRanking: Bool { name == "Group Stage" }
    var sortKey: String { isThirdPlaceRanking ? "ZZZ" : name }

    var title: String {
        if isThirdPlaceRanking {
            return String(localized: "Third-placed teams")
        }
        if name.hasPrefix("Group "), let letter = name.split(separator: " ").last {
            return String(localized: "Group \(String(letter))")
        }
        return name
    }
}

/// One standings row, resolved for display.
struct StandingRowModel: Identifiable {
    let id: String
    let rank: Int
    let teamID: String?
    let flag: String
    let name: String
    let played: Int
    let goalDifference: Int
    let points: Int
    let form: String
    let qualification: String?

    init(standing: Standing, team: Team?) {
        id = standing.id
        rank = standing.rank
        teamID = standing.teamID
        flag = team?.flag ?? ""
        name = team?.name ?? "—"
        played = standing.played
        goalDifference = standing.goalDifference
        points = standing.points
        form = standing.form
        qualification = standing.qualification
    }

    var qualifies: Bool { qualification != nil }

    /// Localized qualification label; reuses the stage names where they match.
    var qualificationLabel: String? {
        guard let qualification else { return nil }
        return Stage(rawValue: qualification)?.displayName ?? qualification
    }
}
