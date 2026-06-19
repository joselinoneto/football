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
    /// Rich detail collections keyed by match record ID, resolved on demand by
    /// `detail(for:)`. Kept raw here so polling stays cheap — only the open
    /// match's display models are built.
    private(set) var eventsByMatch: [String: [MatchEvent]] = [:]
    private(set) var statsByMatch: [String: [MatchStat]] = [:]
    private(set) var lineupsByMatch: [String: [LineupEntry]] = [:]
    private var teamsByID: [String: Team] = [:]
    private var matchesByID: [String: Match] = [:]
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
        let match = matchesByID[matchID]
        return MatchDetailModel(
            row: row,
            timeline: Self.timeline(
                goals: goalsByMatch[matchID] ?? [],
                events: eventsByMatch[matchID] ?? [],
                homeTeamID: match?.homeTeamID,
                teamsByID: teamsByID
            ),
            stats: Self.statsModel(statsByMatch[matchID] ?? [], homeTeamID: match?.homeTeamID),
            lineups: Self.lineupsModel(
                lineupsByMatch[matchID] ?? [],
                match: match,
                teamsByID: teamsByID
            )
        )
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
            async let eventsTask = service.matchEvents()
            async let statsTask = service.matchStats()
            async let lineupsTask = service.lineups()
            let (matches, teams, goals) = try await (matchesTask, teamsTask, goalsTask)
            let (events, stats, lineups) = try await (eventsTask, statsTask, lineupsTask)
            let rows = Self.rows(matches: matches, teams: teams)
            days = Self.groupedByDay(rows)
            rowsByID = Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            teamsByID = Dictionary(teams.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            matchesByID = Dictionary(matches.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let idByNumber = Dictionary(matches.map { ($0.number, $0.id) }, uniquingKeysWith: { first, _ in first })
            goalsByMatch = Self.goalsByMatch(goals, matches: matches, teams: teams)
            eventsByMatch = Self.bucket(events, matchID: \.matchID, number: \.matchNumber, idByNumber: idByNumber)
            statsByMatch = Self.bucket(stats, matchID: \.matchID, number: \.matchNumber, idByNumber: idByNumber)
            lineupsByMatch = Self.bucket(lineups, matchID: \.matchID, number: \.matchNumber, idByNumber: idByNumber)
            if !days.isEmpty {
                phase = .loaded
            }
        } catch {
            if days.isEmpty {
                phase = .failed(Self.loadFailureMessage)
            }
        }
    }

    /// Buckets match-scoped items under their match record ID, resolving the ID
    /// from the linked record or falling back to the match number.
    private static func bucket<T>(
        _ items: [T],
        matchID: (T) -> String?,
        number: (T) -> Int,
        idByNumber: [Int: String]
    ) -> [String: [T]] {
        var out: [String: [T]] = [:]
        for item in items {
            guard let mid = matchID(item) ?? idByNumber[number(item)] else { continue }
            out[mid, default: []].append(item)
        }
        return out
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

/// A match paired with its resolved detail content, for the detail screen.
struct MatchDetailModel {
    let row: MatchRowModel
    let timeline: [TimelineItemModel]
    let stats: MatchStatsModel
    let lineups: MatchLineupsModel
}

// MARK: - Detail builders

extension MatchScheduleViewModel {
    /// "90+2'" → 9002, "90'" → 9000, so stoppage-time entries order correctly.
    static func minuteSortKey(_ minute: String) -> Int {
        let parts = minute.replacingOccurrences(of: "'", with: "").split(separator: "+")
        let base = Int(parts.first ?? "") ?? 0
        let extra = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
        return base * 100 + extra
    }

    /// Goals and non-goal events merged into one minute-ordered timeline.
    static func timeline(
        goals: [GoalRowModel],
        events: [MatchEvent],
        homeTeamID: String?,
        teamsByID: [String: Team]
    ) -> [TimelineItemModel] {
        let goalItems = goals.map { TimelineItemModel(goal: $0) }
        let eventItems = events.map { event -> TimelineItemModel in
            let isHome = event.teamID != nil && event.teamID == homeTeamID
            let flag = event.teamID.flatMap { teamsByID[$0]?.flag } ?? ""
            return TimelineItemModel(event: event, isHome: isHome, flag: flag)
        }
        return (goalItems + eventItems).sorted { $0.sortKey < $1.sortKey }
    }

    static func statsModel(_ stats: [MatchStat], homeTeamID: String?) -> MatchStatsModel {
        let home = stats.first { $0.teamID != nil && $0.teamID == homeTeamID }
        let away = stats.first { $0.id != home?.id }
        return MatchStatsModel(home: home, away: away)
    }

    static func lineupsModel(
        _ lineups: [LineupEntry],
        match: Match?,
        teamsByID: [String: Team]
    ) -> MatchLineupsModel {
        func side(_ teamID: String?) -> TeamLineupModel {
            let entries = lineups.filter { $0.teamID != nil && $0.teamID == teamID }
            let team = teamID.flatMap { teamsByID[$0] }
            return TeamLineupModel(
                flag: team?.flag ?? "",
                name: team?.name ?? "",
                entries: entries
            )
        }
        return MatchLineupsModel(home: side(match?.homeTeamID), away: side(match?.awayTeamID))
    }
}

/// One entry in the merged match timeline — a goal or a card/sub/VAR event.
struct TimelineItemModel: Identifiable {
    let id: String
    let minute: String
    let sortKey: Int
    let isHome: Bool
    let flag: String
    /// Non-nil for goals.
    let goalType: GoalType?
    /// Non-nil for non-goal events.
    let eventType: MatchEventType?
    /// Scorer, or the carded / substituted-off player.
    let primary: String
    /// Goal tag (pen/OG), or the player coming on for a substitution.
    let secondary: String?

    init(goal: GoalRowModel) {
        id = goal.id
        minute = goal.minute
        sortKey = goal.sortKey
        isHome = goal.isHome
        flag = goal.flag
        goalType = goal.type
        eventType = nil
        primary = goal.scorer
        secondary = goal.type.shortTag
    }

    init(event: MatchEvent, isHome: Bool, flag: String) {
        id = event.id
        minute = event.minute
        sortKey = MatchScheduleViewModel.minuteSortKey(event.minute)
        self.isHome = isHome
        self.flag = flag
        goalType = nil
        eventType = event.type
        primary = event.player
        secondary = event.player2
    }
}

/// Per-team match statistics, as comparison rows for the detail screen.
struct MatchStatsModel {
    let rows: [StatComparisonRow]

    init(home: MatchStat?, away: MatchStat?) {
        var rows: [StatComparisonRow] = []
        func percentValue(_ s: String?) -> Double? {
            s.flatMap { Double($0.replacingOccurrences(of: "%", with: "")) }
        }
        rows.append(contentsOf: [
            StatComparisonRow(title: String(localized: "Possession"),
                              home: home?.possession, away: away?.possession,
                              homeValue: percentValue(home?.possession),
                              awayValue: percentValue(away?.possession)),
            StatComparisonRow(title: String(localized: "Shots"),
                              homeInt: home?.shotsTotal, awayInt: away?.shotsTotal),
            StatComparisonRow(title: String(localized: "Shots on target"),
                              homeInt: home?.shotsOnGoal, awayInt: away?.shotsOnGoal),
            StatComparisonRow(title: String(localized: "Corners"),
                              homeInt: home?.corners, awayInt: away?.corners),
            StatComparisonRow(title: String(localized: "Fouls"),
                              homeInt: home?.fouls, awayInt: away?.fouls),
            StatComparisonRow(title: String(localized: "Passing accuracy"),
                              home: home?.passesPercent, away: away?.passesPercent,
                              homeValue: percentValue(home?.passesPercent),
                              awayValue: percentValue(away?.passesPercent)),
            StatComparisonRow(title: String(localized: "Expected goals"),
                              home: home?.expectedGoals.map { String(format: "%.2f", $0) },
                              away: away?.expectedGoals.map { String(format: "%.2f", $0) },
                              homeValue: home?.expectedGoals, awayValue: away?.expectedGoals),
        ])
        self.rows = rows.filter { $0.hasValue }
    }

    var isEmpty: Bool { rows.isEmpty }
}

struct StatComparisonRow: Identifiable {
    let id: String
    let title: String
    let home: String
    let away: String
    /// Home share of the total, 0...1, for the comparison bar; nil if neither
    /// side reported a comparable number.
    let homeFraction: Double?
    let hasValue: Bool

    init(title: String, home: String?, away: String?, homeValue: Double?, awayValue: Double?) {
        self.id = title
        self.title = title
        self.home = home ?? "–"
        self.away = away ?? "–"
        self.hasValue = home != nil || away != nil
        let total = (homeValue ?? 0) + (awayValue ?? 0)
        self.homeFraction = total > 0 ? (homeValue ?? 0) / total : nil
    }

    init(title: String, homeInt: Int?, awayInt: Int?) {
        self.init(
            title: title,
            home: homeInt.map { "\($0)" },
            away: awayInt.map { "\($0)" },
            homeValue: homeInt.map(Double.init),
            awayValue: awayInt.map(Double.init)
        )
    }
}

/// Both sides' lineups for the detail screen.
struct MatchLineupsModel {
    let home: TeamLineupModel
    let away: TeamLineupModel
    var isEmpty: Bool { home.starters.isEmpty && away.starters.isEmpty }
}

struct TeamLineupModel {
    let flag: String
    let name: String
    let starters: [LineupRowModel]
    let bench: [LineupRowModel]

    init(flag: String, name: String, entries: [LineupEntry]) {
        self.flag = flag
        self.name = name
        func sorted(_ entries: [LineupEntry]) -> [LineupRowModel] {
            entries
                .sorted { lhs, rhs in
                    let l = lhs.position?.sortOrder ?? 99
                    let r = rhs.position?.sortOrder ?? 99
                    if l != r { return l < r }
                    return (lhs.number ?? .max) < (rhs.number ?? .max)
                }
                .map(LineupRowModel.init)
        }
        starters = sorted(entries.filter(\.started))
        bench = sorted(entries.filter { !$0.started })
    }
}

struct LineupRowModel: Identifiable {
    let id: String
    let number: Int?
    let name: String
    let positionCode: String?
    let captain: Bool
    let rating: String?
    let goals: Int

    init(_ entry: LineupEntry) {
        id = entry.id
        number = entry.number
        name = entry.player
        positionCode = entry.position?.shortCode
        captain = entry.captain
        rating = entry.rating.map { String(format: "%.1f", $0) }
        goals = entry.goals
    }
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
