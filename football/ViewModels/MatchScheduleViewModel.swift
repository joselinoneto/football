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
    /// Goal timelines keyed by match record ID, sorted by minute.
    private(set) var goalsByMatch: [String: [GoalRowModel]] = [:]
    /// Rows keyed by match record ID, for the detail screen lookup.
    private(set) var rowsByID: [String: MatchRowModel] = [:]
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

    /// Shows whatever is in the local store immediately, then keeps refreshing
    /// from the network on an adaptive cadence — fast while a match is live,
    /// slower otherwise. The loop ends when the owning `.task` is cancelled
    /// (i.e. the screen goes away), so there is no manual lifecycle to manage.
    func start() async {
        await loadFromStore()
        while !Task.isCancelled {
            await refresh()
            try? await Task.sleep(for: .seconds(pollInterval))
        }
    }

    /// Seconds between polls: tight while anything is live so scores, the match
    /// minute, and goals update on their own; relaxed otherwise, still often
    /// enough to catch a kickoff flipping a match to live.
    private var pollInterval: Int {
        let anyLive = days.contains { $0.rows.contains { $0.status == .live } }
        return anyLive ? 30 : 180
    }

    /// The match plus its goal timeline, resolved live from the store-backed
    /// state. Reading the observable properties here keeps the detail screen
    /// in sync as polling updates come in.
    func detail(for matchID: String) -> MatchDetailModel? {
        guard let row = rowsByID[matchID] else { return nil }
        return MatchDetailModel(row: row, goals: goalsByMatch[matchID] ?? [])
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
            async let teamsTask = service.teams()
            async let matchesTask = service.matches()
            async let goalsTask = service.goals()
            let (matches, teams, goals) = try await (matchesTask, teamsTask, goalsTask)
            let rows = Self.rows(matches: matches, teams: teams)
            days = Self.groupedByDay(rows)
            rowsByID = Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            goalsByMatch = Self.goalsByMatch(goals, matches: matches, teams: teams)
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

    /// Groups goals under their match record ID, resolving each scoring side's
    /// flag and whether it is the home team, then ordering by match minute.
    private static func goalsByMatch(_ goals: [Goal], matches: [Match], teams: [Team]) -> [String: [GoalRowModel]] {
        let teamsByID = Dictionary(teams.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let matchIDByNumber = Dictionary(matches.map { ($0.number, $0.id) }, uniquingKeysWith: { first, _ in first })
        let homeTeamByMatch = Dictionary(matches.map { ($0.id, $0.homeTeamID) }, uniquingKeysWith: { first, _ in first })

        var result: [String: [GoalRowModel]] = [:]
        for goal in goals {
            guard let matchID = goal.matchID ?? matchIDByNumber[goal.matchNumber] else { continue }
            let flag = goal.teamID.flatMap { teamsByID[$0]?.flag } ?? ""
            let isHome = goal.teamID != nil && goal.teamID == (homeTeamByMatch[matchID] ?? nil)
            result[matchID, default: []].append(GoalRowModel(goal: goal, flag: flag, isHome: isHome))
        }
        for matchID in result.keys {
            result[matchID]?.sort { $0.sortKey < $1.sortKey }
        }
        return result
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
    /// Live match clock, e.g. "67'"; only meaningful while `status == .live`.
    let minute: String?
    let home: Side
    let away: Side

    init(match: Match, teamsByID: [String: Team]) {
        id = match.id
        kickoff = match.kickoff
        stage = match.stage
        venue = match.venue
        status = match.status
        minute = match.minute
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

/// A match paired with its goal timeline, for the detail screen.
struct MatchDetailModel {
    let row: MatchRowModel
    let goals: [GoalRowModel]
}

/// One goal, resolved for display: scoring side's flag, which side it's on,
/// and a numeric key so "90+2'" sorts after "90'".
struct GoalRowModel: Identifiable {
    let id: String
    let minute: String
    let sortKey: Int
    let scorer: String
    let type: GoalType
    let flag: String
    let isHome: Bool

    init(goal: Goal, flag: String, isHome: Bool) {
        id = goal.id
        minute = goal.minute
        sortKey = Self.sortKey(goal.minute)
        scorer = goal.scorer
        type = goal.type
        self.flag = flag
        self.isHome = isHome
    }

    /// "90+2'" → 9002, "90'" → 9000, so stoppage-time goals order correctly.
    private static func sortKey(_ minute: String) -> Int {
        let parts = minute.replacingOccurrences(of: "'", with: "").split(separator: "+")
        let base = Int(parts.first ?? "") ?? 0
        let extra = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
        return base * 100 + extra
    }
}
