import Foundation
import Observation
import FootballCore
import FootballManager

@MainActor
@Observable
final class MatchScheduleViewModel {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    private(set) var phase: Phase = .loading
    private(set) var days: [MatchDay] = []

    private let service: any FootballService

    init(service: any FootballService) {
        self.service = service
    }

    /// Shows whatever is in the local store immediately, then refreshes from
    /// the network.
    func start() async {
        await loadFromStore()
        await refresh()
    }

    func refresh() async {
        do {
            try await service.refresh()
            await loadFromStore()
        } catch {
            // Keep showing cached data if we have it; only surface the error
            // when there is nothing to show.
            if days.isEmpty {
                phase = .failed(Self.loadFailureMessage)
            }
        }
    }

    private func loadFromStore() async {
        do {
            async let teams = service.teams()
            async let matches = service.matches()
            let rows = try await Self.rows(matches: matches, teams: teams)
            days = Self.groupedByDay(rows)
            if !days.isEmpty {
                phase = .loaded
            }
        } catch {
            if days.isEmpty {
                phase = .failed(Self.loadFailureMessage)
            }
        }
    }

    private static var loadFailureMessage: String {
        String(localized: "Could not load the matches. Check your connection and try again.")
    }

    // MARK: Presentation

    private static func rows(matches: [Match], teams: [Team]) -> [MatchRowModel] {
        let teamsByID = Dictionary(teams.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return matches.map { MatchRowModel(match: $0, teamsByID: teamsByID) }
    }

    private static func groupedByDay(_ rows: [MatchRowModel]) -> [MatchDay] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: rows) { calendar.startOfDay(for: $0.kickoff) }
        return grouped
            .sorted { $0.key < $1.key }
            .map { date, rows in
                MatchDay(date: date, rows: rows.sorted { $0.kickoff < $1.kickoff })
            }
    }
}

struct MatchDay: Identifiable {
    let date: Date
    let rows: [MatchRowModel]

    var id: Date { date }

    var title: String {
        date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}

/// Everything a row needs, resolved up front so the view stays dumb.
struct MatchRowModel: Identifiable {
    struct Side {
        let flag: String
        let name: String
        let score: Int?
    }

    let id: String
    let kickoff: Date
    let stage: Stage
    let venue: String
    let status: MatchStatus
    let home: Side
    let away: Side

    init(match: Match, teamsByID: [String: Team]) {
        id = match.id
        kickoff = match.kickoff
        stage = match.stage
        venue = match.venue
        status = match.status
        home = Side(
            teamID: match.homeTeamID,
            fallbackName: match.titleSides?.home,
            score: match.homeScore,
            teamsByID: teamsByID
        )
        away = Side(
            teamID: match.awayTeamID,
            fallbackName: match.titleSides?.away,
            score: match.awayScore,
            teamsByID: teamsByID
        )
    }

    var detail: String {
        stage == .group ? venue : "\(stage.displayName) · \(venue)"
    }

    var showsScore: Bool { status != .scheduled }
}

extension MatchRowModel.Side {
    init(teamID: String?, fallbackName: String?, score: Int?, teamsByID: [String: Team]) {
        if let teamID, let team = teamsByID[teamID] {
            self.init(flag: team.flag, name: team.name, score: score)
        } else {
            // Knockout slot not decided yet, e.g. "Winner Match 74".
            self.init(
                flag: "",
                name: fallbackName ?? String(localized: "To be decided"),
                score: score
            )
        }
    }
}
