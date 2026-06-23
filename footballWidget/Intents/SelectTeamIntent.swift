import AppIntents
import FootballCore
import FootballManager

/// Widget configuration: pick a team to follow, or leave it empty (the default)
/// to show today's games.
struct SelectTeamIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Match"
    static var description = IntentDescription("Follow a team, or show today's games.")

    @Parameter(title: "Team")
    var team: TeamEntity?

    init() {}
}

/// A selectable team, backed by the shared store the app keeps up to date.
struct TeamEntity: AppEntity {
    let id: String
    let name: String
    let code: String
    let flag: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Team" }
    static var defaultQuery = TeamQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(flag) \(name)", subtitle: "\(code)")
    }

    init(id: String, name: String, code: String, flag: String) {
        self.id = id
        self.name = name
        self.code = code
        self.flag = flag
    }

    init(_ team: Team) {
        self.init(id: team.id, name: team.name, code: team.code, flag: team.flag)
    }
}

struct TeamQuery: EntityQuery {
    func entities(for identifiers: [TeamEntity.ID]) async throws -> [TeamEntity] {
        let teams = (try? await WidgetDependencies.service.teams()) ?? []
        let wanted = Set(identifiers)
        return teams.filter { wanted.contains($0.id) }.map(TeamEntity.init)
    }

    func suggestedEntities() async throws -> [TeamEntity] {
        let teams = (try? await WidgetDependencies.service.teams()) ?? []
        return teams.map(TeamEntity.init).sorted { $0.name < $1.name }
    }
}
