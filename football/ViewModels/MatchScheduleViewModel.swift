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
    var selectedFilter: MatchFilter = .all

    /// The grouped days narrowed down to the active filter, dropping any day
    /// left without matching matches.
    var filteredDays: [MatchDay] {
        switch selectedFilter {
        case .all:
            return days
        case .today:
            return days.filter(\.isToday)
        case .upcoming:
            return days.compactMap { $0.keepingRows { $0.status != .finished } }
        case .finished:
            return days.compactMap { $0.keepingRows { $0.status == .finished } }
        }
    }

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
        let today = calendar.startOfDay(for: Date())
        let grouped = Dictionary(grouping: rows) { calendar.startOfDay(for: $0.kickoff) }
        return grouped
            .map { date, rows in
                MatchDay(
                    date: date,
                    isToday: date == today,
                    rows: rows.sorted { $0.kickoff < $1.kickoff }
                )
            }
            // Today's matches pinned to the top, every other day in date order.
            .sorted { lhs, rhs in
                if lhs.isToday != rhs.isToday { return lhs.isToday }
                return lhs.date < rhs.date
            }
    }
}

enum MatchFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case upcoming
    case finished

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: String(localized: "All")
        case .today: String(localized: "Today")
        case .upcoming: String(localized: "Upcoming")
        case .finished: String(localized: "Finished")
        }
    }
}

struct MatchDay: Identifiable {
    let date: Date
    let isToday: Bool
    let rows: [MatchRowModel]

    var id: Date { date }

    var title: String {
        if isToday {
            return String(localized: "Today")
        }
        return date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    /// Returns a copy keeping only matching rows, or nil if none remain.
    func keepingRows(_ isIncluded: (MatchRowModel) -> Bool) -> MatchDay? {
        let kept = rows.filter(isIncluded)
        return kept.isEmpty ? nil : MatchDay(date: date, isToday: isToday, rows: kept)
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
