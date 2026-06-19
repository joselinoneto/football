import Foundation
import Observation
import FootballCore
import FootballManager

@MainActor
@Observable
final class TeamsViewModel {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    private(set) var phase: Phase = .loading
    private(set) var groups: [TeamsGroup] = []

    private var teamsByID: [String: TeamRowModel] = [:]
    private var squadsByTeam: [String: [SquadMember]] = [:]

    private let service: any FootballService

    init(service: any FootballService) {
        self.service = service
    }

    func start() async {
        await loadFromStore()
        await refresh()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(120))
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

    func team(for id: String) -> TeamRowModel? { teamsByID[id] }

    /// The team's roster, split into goalkeeper/defender/midfielder/attacker
    /// sections, each ordered by shirt number.
    func squadSections(for teamID: String) -> [SquadLineSection] {
        let members = squadsByTeam[teamID] ?? []
        return Dictionary(grouping: members, by: { $0.position })
            .map { position, members in
                SquadLineSection(
                    position: position,
                    members: members
                        .sorted { ($0.number ?? .max, $0.player) < ($1.number ?? .max, $1.player) }
                        .map(SquadRowModel.init)
                )
            }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private func loadFromStore() async {
        do {
            async let teamsTask = service.teams()
            async let squadsTask = service.squads()
            let (teams, squads) = try await (teamsTask, squadsTask)
            teamsByID = Dictionary(
                teams.map { ($0.id, TeamRowModel(team: $0)) },
                uniquingKeysWith: { first, _ in first }
            )
            squadsByTeam = Dictionary(grouping: squads.compactMap { m in m.teamID.map { ($0, m) } },
                                      by: { $0.0 }).mapValues { $0.map(\.1) }
            groups = Self.build(teams)
            if !groups.isEmpty { phase = .loaded }
        } catch {
            if groups.isEmpty { phase = .failed(Self.failureMessage) }
        }
    }

    private static var failureMessage: String {
        String(localized: "Could not load the teams. Check your connection and try again.")
    }

    private static func build(_ teams: [Team]) -> [TeamsGroup] {
        Dictionary(grouping: teams, by: \.group)
            .map { letter, teams in
                TeamsGroup(letter: letter, teams: teams.sorted { $0.name < $1.name }.map(TeamRowModel.init))
            }
            .sorted { $0.letter < $1.letter }
    }
}

struct TeamsGroup: Identifiable {
    let letter: String
    let teams: [TeamRowModel]
    var id: String { letter }
    var title: String { String(localized: "Group \(letter)") }
}

struct TeamRowModel: Identifiable {
    let id: String
    let name: String
    let code: String
    let flag: String
    let group: String

    init(team: Team) {
        id = team.id
        name = team.name
        code = team.code
        flag = team.flag
        group = team.group
    }
}

struct SquadLineSection: Identifiable {
    let position: PlayerPosition?
    let members: [SquadRowModel]

    var id: String { position?.rawValue ?? "other" }
    var sortOrder: Int { position?.sortOrder ?? 99 }
    var title: String { position?.displayName ?? String(localized: "Squad") }
}

struct SquadRowModel: Identifiable {
    let id: String
    let number: Int?
    let name: String
    let age: Int?

    init(_ member: SquadMember) {
        id = member.id
        number = member.number
        name = member.player
        age = member.age
    }
}
