import Foundation
import Observation
import FootballCore
import FootballManager

@MainActor
@Observable
public final class MatchScheduleViewModel {
    public enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    public private(set) var phase: Phase = .loading
    public private(set) var days: [MatchDay] = []
    /// Goal timelines keyed by match record ID, sorted by minute.
    private(set) var goalsByMatch: [String: [GoalRowModel]] = [:]
    /// Rows keyed by match record ID, for the detail screen lookup.
    private(set) var rowsByID: [String: MatchRowModel] = [:]
    /// Rich detail collections keyed by match record ID, resolved on demand by
    /// `detail(for:)`. Kept raw here so polling stays cheap — only the open
    /// match's display models are built.
    private(set) var eventsByMatch: [String: [MatchEvent]] = [:]
    private(set) var statsByMatch: [String: [MatchStat]] = [:]
    /// Group standings, shown in the Matches screen's Standings segment.
    public private(set) var standingsGroups: [StandingsGroup] = []
    /// Set once the standings have been fetched from the network, so a reappear
    /// of the Standings section doesn't refetch. The group stage is complete and
    /// these tables no longer change, so a single load per session is enough.
    private var standingsRefreshed = false
    private var teamsByID: [String: Team] = [:]
    private var matchesByID: [String: Match] = [:]
    private var squadsByTeam: [String: [SquadMember]] = [:]
    public var selectedFilter: MatchFilter = .all

    /// Called on the main actor after every store reload with the freshly
    /// loaded days. The iOS app uses it to reload the Home Screen widget and
    /// drive the Live Activity; left nil elsewhere (e.g. the Watch app).
    public var onStoreReloaded: (@MainActor ([MatchDay]) -> Void)?

    /// Set when the app is opened from the widget or Live Activity; the
    /// schedule screen presents this match's detail.
    public var deepLinkedMatchID: String?

    /// Opens the given match's detail (used by the widget/Live-Activity deep link).
    public func openMatch(id: String) { deepLinkedMatchID = id }

    /// A representative finished match that has a goal timeline — used by
    /// screenshot automation to land on a populated match-detail screen. Falls
    /// back to any finished match, then any match at all.
    public var sampleMatchID: String? {
        let finished = days.flatMap(\.rows).filter { $0.status == .finished }
        if let withGoals = finished.first(where: { !(goalsByMatch[$0.id]?.isEmpty ?? true) }) {
            return withGoals.id
        }
        return finished.first?.id ?? days.flatMap(\.rows).first?.id
    }

    /// The grouped days narrowed down to the active filter, dropping any day
    /// left without matching matches.
    public var filteredDays: [MatchDay] {
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

    public init(service: any FootballService) {
        self.service = service
    }

    /// Shows whatever is in the local store immediately, then keeps refreshing
    /// from the network on an adaptive cadence — fast while a match is live,
    /// slower otherwise. The loop ends when the owning `.task` is cancelled
    /// (i.e. the screen goes away), so there is no manual lifecycle to manage.
    public func start() async {
        await loadFromStore()
        // One full refresh on appear pulls the static reference tables (Teams,
        // Squads, Standings …); the loop then polls only the live-changing
        // tables, keeping the per-poll request count low.
        await refresh()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(pollInterval))
            await refreshLive()
        }
    }

    /// Seconds between polls: tight while anything is live so scores, the match
    /// minute, and goals update on their own; relaxed otherwise, still often
    /// enough to catch a kickoff flipping a match to live.
    private var pollInterval: Int {
        let anyLive = days.contains { $0.rows.contains { $0.status == .live } }
        return anyLive ? 30 : 180
    }

    /// The match plus its resolved detail content, read live from the
    /// store-backed state. Reading the observable properties here keeps the
    /// detail screen in sync as polling updates come in.
    public func detail(for matchID: String) -> MatchDetailModel? {
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
            stats: Self.statsModel(statsByMatch[matchID] ?? [], homeTeamID: match?.homeTeamID)
        )
    }

    /// A team's display row, for the team detail screen reached by tapping a
    /// country name (e.g. from the standings).
    public func team(for teamID: String) -> TeamRowModel? {
        teamsByID[teamID].map(TeamRowModel.init)
    }

    /// The tournament champion, resolved from a finished Final that has a
    /// recorded winner. `nil` until the Final is played — which is exactly what
    /// gates the celebratory Champion screen shown atop the knockout Final round.
    public var champion: ChampionModel? {
        guard let final = days.flatMap(\.rows)
            .first(where: { $0.stage == .final && $0.status == .finished }),
              let winnerID = final.winnerTeamID else { return nil }
        let winnerIsHome = final.home.teamID == winnerID
        let winner = winnerIsHome ? final.home : final.away
        let runnerUp = winnerIsHome ? final.away : final.home
        // Guard the winner is a resolved team, so the celebration can link to it.
        guard winner.teamID != nil else { return nil }
        return ChampionModel(
            teamID: winnerID,
            name: winner.name,
            flag: winner.flag,
            runnerUpName: runnerUp.name,
            runnerUpFlag: runnerUp.flag,
            score: winner.score,
            runnerUpScore: runnerUp.score,
            penaltyScore: winner.penaltyScore,
            runnerUpPenaltyScore: runnerUp.penaltyScore,
            decidedBy: final.decidedBy,
            venue: final.venue,
            finalMatchID: final.id,
            highlights: goalsByMatch[final.id] ?? []
        )
    }

    /// Every loaded team, ordered by group then name — for the favorite-team
    /// picker in Settings. Empty until the first store load completes.
    public var allTeams: [Team] {
        teamsByID.values.sorted { ($0.group, $0.name) < ($1.group, $1.name) }
    }

    /// Every match the team has featured in, most-recent first — the results
    /// list on the team detail screen. Reads the same store-backed rows as the
    /// schedule, so it reflects live updates while the screen is open.
    public func matches(for teamID: String) -> [TeamMatchRowModel] {
        days.flatMap(\.rows)
            .filter { $0.home.teamID == teamID || $0.away.teamID == teamID }
            .sorted { $0.kickoff > $1.kickoff }
            .map { TeamMatchRowModel(row: $0, teamID: teamID) }
    }

    /// The team's roster, split into goalkeeper/defender/midfielder/attacker
    /// sections, each ordered by shirt number.
    public func squadSections(for teamID: String) -> [SquadLineSection] {
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

    public func refresh() async {
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

    /// The polling payload: refreshes only the tables that change during a live
    /// match (Matches, Goals, Match Stats, Match Events), then reloads from the
    /// store. Static reference data is loaded once by `start()`'s initial
    /// `refresh()` and on pull-to-refresh, so it stays out of the loop.
    public func refreshLive() async {
        do {
            try await service.refreshLive()
            await loadFromStore()
        } catch {
            if days.isEmpty {
                phase = .failed(Self.loadFailureMessage)
            }
        }
    }

    /// Refreshes just the standings, then updates the standings groups in place.
    /// Driven by the Standings section appearing (not the polling loop). The
    /// group stage is finished and these tables no longer change, so it loads
    /// once per session — a reappear of the section is a no-op (the store-backed
    /// `standingsGroups` is already populated from the initial load).
    public func refreshStandings() async {
        guard !standingsRefreshed else { return }
        try? await service.refreshStandings()
        if let standings = try? await service.standings() {
            standingsGroups = Self.standingsGroups(standings, teamsByID: teamsByID)
        }
        standingsRefreshed = true
    }

    /// Lightweight refresh for background app refresh: pulls just scores
    /// (Teams + Matches) and reloads from the store, which fires
    /// `onStoreReloaded` → widget reload + Live Activity update. Best-effort:
    /// failures keep whatever is cached.
    public func refreshScores() async {
        try? await service.refreshScores()
        await loadFromStore()
    }

    private func loadFromStore() async {
        do {
            async let teamsTask = service.teams()
            async let matchesTask = service.matches()
            async let goalsTask = service.goals()
            async let eventsTask = service.matchEvents()
            async let statsTask = service.matchStats()
            async let standingsTask = service.standings()
            async let squadsTask = service.squads()
            let (matches, teams, goals) = try await (matchesTask, teamsTask, goalsTask)
            let (events, stats) = try await (eventsTask, statsTask)
            let (standings, squads) = try await (standingsTask, squadsTask)
            let rows = Self.rows(matches: matches, teams: teams)
            days = Self.groupedByDay(rows)
            rowsByID = Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            teamsByID = Dictionary(teams.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            matchesByID = Dictionary(matches.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let idByNumber = Dictionary(matches.map { ($0.number, $0.id) }, uniquingKeysWith: { first, _ in first })
            goalsByMatch = Self.goalsByMatch(goals, matches: matches, teams: teams)
            eventsByMatch = Self.bucket(events, matchID: \.matchID, number: \.matchNumber, idByNumber: idByNumber)
            statsByMatch = Self.bucket(stats, matchID: \.matchID, number: \.matchNumber, idByNumber: idByNumber)
            standingsGroups = Self.standingsGroups(standings, teamsByID: teamsByID)
            squadsByTeam = Dictionary(grouping: squads.compactMap { m in m.teamID.map { ($0, m) } },
                                      by: { $0.0 }).mapValues { $0.map(\.1) }
            if !days.isEmpty {
                phase = .loaded
            }
            onStoreReloaded?(days)
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
        String(localized: "Could not load the matches. Check your connection and try again.", bundle: .module)
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

    private static func standingsGroups(_ standings: [Standing], teamsByID: [String: Team]) -> [StandingsGroup] {
        Dictionary(grouping: standings, by: \.group)
            // Drop the pooled third-placed-teams ranking ("Group Stage") — its
            // data is unreliable and it isn't useful in the app.
            .filter { name, _ in name != "Group Stage" }
            .map { name, rows in
                StandingsGroup(
                    name: name,
                    rows: rows.sorted { $0.rank < $1.rank }
                        .map { StandingRowModel(standing: $0, team: $0.teamID.flatMap { teamsByID[$0] }) }
                )
            }
            .sorted { $0.name < $1.name }
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
                    // Live matches float to the top of their day; the rest stay
                    // in kickoff order.
                    rows: rows.sorted { lhs, rhs in
                        let lhsLive = lhs.status == .live
                        let rhsLive = rhs.status == .live
                        if lhsLive != rhsLive { return lhsLive }
                        return lhs.kickoff < rhs.kickoff
                    }
                )
            }
            // Today pinned to the top, then completed days latest-first, with
            // upcoming days after in soonest-first order.
            .sorted { lhs, rhs in
                if lhs.isToday != rhs.isToday { return lhs.isToday }
                let lhsPast = lhs.date < today
                let rhsPast = rhs.date < today
                if lhsPast != rhsPast { return lhsPast }
                // Completed days descending (latest first); upcoming ascending.
                return lhsPast ? lhs.date > rhs.date : lhs.date < rhs.date
            }
    }
}

public enum MatchFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case upcoming
    case finished

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: String(localized: "All", bundle: .module)
        case .today: String(localized: "Today", bundle: .module)
        case .upcoming: String(localized: "Upcoming", bundle: .module)
        case .finished: String(localized: "Finished", bundle: .module)
        }
    }
}

public struct MatchDay: Identifiable {
    public let date: Date
    public let isToday: Bool
    public let rows: [MatchRowModel]

    public var id: Date { date }

    public var title: String {
        if isToday {
            return String(localized: "Today", bundle: .module)
        }
        return date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    init(date: Date, isToday: Bool, rows: [MatchRowModel]) {
        self.date = date
        self.isToday = isToday
        self.rows = rows
    }

    /// Returns a copy keeping only matching rows, or nil if none remain.
    public func keepingRows(_ isIncluded: (MatchRowModel) -> Bool) -> MatchDay? {
        let kept = rows.filter(isIncluded)
        return kept.isEmpty ? nil : MatchDay(date: date, isToday: isToday, rows: kept)
    }
}

/// Everything a row needs, resolved up front so the view stays dumb.
public struct MatchRowModel: Identifiable {
    public struct Side {
        /// Linked Team record ID; nil when the team isn't decided yet. Lets the
        /// detail screen turn the team name into a link to its squad.
        public let teamID: String?
        public let flag: String
        public let name: String
        /// Three-letter country code, e.g. "BRA"; empty when undecided.
        public let code: String
        public let score: Int?
        /// Penalty-shootout score; non-nil only for a tie settled on penalties.
        public let penaltyScore: Int?
    }

    public let id: String
    /// Official match number 1–104.
    public let number: Int
    public let kickoff: Date
    public let stage: Stage
    public let venue: String
    public let status: MatchStatus
    /// Live match clock, e.g. "67'"; only meaningful while `status == .live`.
    public let minute: String?
    public let home: Side
    public let away: Side
    /// Linked Team record ID of the winner; nil for a regulation draw or a
    /// match that isn't finished yet.
    public let winnerTeamID: String?
    /// How the result was settled; nil until the match is finished.
    public let decidedBy: DecidedBy?

    public init(match: Match, teamsByID: [String: Team]) {
        id = match.id
        number = match.number
        kickoff = match.kickoff
        stage = match.stage
        venue = match.venue
        status = match.status
        minute = match.minute
        winnerTeamID = match.winnerTeamID
        decidedBy = match.decidedBy
        home = Side(
            teamID: match.homeTeamID,
            fallbackName: match.titleSides?.home,
            score: match.homeScore,
            penaltyScore: match.homePenalties,
            teamsByID: teamsByID
        )
        away = Side(
            teamID: match.awayTeamID,
            fallbackName: match.titleSides?.away,
            score: match.awayScore,
            penaltyScore: match.awayPenalties,
            teamsByID: teamsByID
        )
    }

    public var detail: String {
        stage == .group ? venue : "\(stage.displayName) · \(venue)"
    }

    public var showsScore: Bool { status != .scheduled }

    /// True when the tie was settled by a penalty shootout (both sides carry a
    /// shootout score). Used to render the "(5–4)" detail next to the scores.
    public var wentToPenalties: Bool {
        home.penaltyScore != nil && away.penaltyScore != nil
    }

    /// Whether `side` won, using the recorded winner when present (so a
    /// shootout win on a level scoreline still highlights correctly) and
    /// falling back to the scoreline for older records without a winner link.
    public func didWin(_ side: Side) -> Bool {
        guard status == .finished else { return false }
        if let winnerTeamID, let teamID = side.teamID {
            return teamID == winnerTeamID
        }
        let mine = side.score ?? 0
        let theirs = (side.teamID == home.teamID ? away.score : home.score) ?? 0
        return mine > theirs
    }
}

extension MatchRowModel.Side {
    init(teamID: String?, fallbackName: String?, score: Int?, penaltyScore: Int?,
         teamsByID: [String: Team]) {
        if let teamID, let team = teamsByID[teamID] {
            self.init(teamID: teamID, flag: team.flag, name: team.name, code: team.code,
                      score: score, penaltyScore: penaltyScore)
        } else {
            // Knockout slot not decided yet, e.g. "Winner Match 74".
            self.init(
                teamID: nil,
                flag: "",
                name: fallbackName ?? String(localized: "To be decided", bundle: .module),
                code: "",
                score: score,
                penaltyScore: penaltyScore
            )
        }
    }
}

/// A match paired with its resolved detail content, for the detail screen.
public struct MatchDetailModel {
    public let row: MatchRowModel
    public let timeline: [TimelineItemModel]
    public let stats: MatchStatsModel
}

// MARK: - Detail builders

extension MatchScheduleViewModel {
    /// "90+2'" → 9002, "90'" → 9000, so stoppage-time entries order correctly.
    /// `nonisolated` so the (nonisolated) `TimelineItemModel.init` can call it.
    nonisolated static func minuteSortKey(_ minute: String) -> Int {
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
}

/// One entry in the merged match timeline — a goal or a card/sub/VAR event.
public struct TimelineItemModel: Identifiable {
    public let id: String
    public let minute: String
    let sortKey: Int
    public let isHome: Bool
    public let flag: String
    /// Non-nil for goals.
    public let goalType: GoalType?
    /// Non-nil for non-goal events.
    public let eventType: MatchEventType?
    /// Scorer, or the carded / substituted-off player.
    public let primary: String
    /// Goal tag (pen/OG), or the player coming on for a substitution.
    public let secondary: String?

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
public struct MatchStatsModel {
    public let rows: [StatComparisonRow]

    init(home: MatchStat?, away: MatchStat?) {
        var rows: [StatComparisonRow] = []
        func percentValue(_ s: String?) -> Double? {
            s.flatMap { Double($0.replacingOccurrences(of: "%", with: "")) }
        }
        rows.append(contentsOf: [
            StatComparisonRow(title: String(localized: "Possession", bundle: .module),
                              home: home?.possession, away: away?.possession,
                              homeValue: percentValue(home?.possession),
                              awayValue: percentValue(away?.possession)),
            StatComparisonRow(title: String(localized: "Shots", bundle: .module),
                              homeInt: home?.shotsTotal, awayInt: away?.shotsTotal),
            StatComparisonRow(title: String(localized: "Shots on target", bundle: .module),
                              homeInt: home?.shotsOnGoal, awayInt: away?.shotsOnGoal),
            StatComparisonRow(title: String(localized: "Corners", bundle: .module),
                              homeInt: home?.corners, awayInt: away?.corners),
            StatComparisonRow(title: String(localized: "Fouls", bundle: .module),
                              homeInt: home?.fouls, awayInt: away?.fouls),
            StatComparisonRow(title: String(localized: "Passing accuracy", bundle: .module),
                              home: home?.passesPercent, away: away?.passesPercent,
                              homeValue: percentValue(home?.passesPercent),
                              awayValue: percentValue(away?.passesPercent)),
            StatComparisonRow(title: String(localized: "Expected goals", bundle: .module),
                              home: home?.expectedGoals.map { String(format: "%.2f", $0) },
                              away: away?.expectedGoals.map { String(format: "%.2f", $0) },
                              homeValue: home?.expectedGoals, awayValue: away?.expectedGoals),
        ])
        self.rows = rows.filter { $0.hasValue }
    }

    public var isEmpty: Bool { rows.isEmpty }
}

public struct StatComparisonRow: Identifiable {
    public let id: String
    public let title: String
    public let home: String
    public let away: String
    /// Home share of the total, 0...1, for the comparison bar; nil if neither
    /// side reported a comparable number.
    public let homeFraction: Double?
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

/// One goal, resolved for display: scoring side's flag, which side it's on,
/// and a numeric key so "90+2'" sorts after "90'".
public struct GoalRowModel: Identifiable {
    public let id: String
    public let minute: String
    let sortKey: Int
    public let scorer: String
    public let type: GoalType
    public let flag: String
    public let isHome: Bool

    init(goal: Goal, flag: String, isHome: Bool) {
        id = goal.id
        minute = goal.minute
        sortKey = Self.sortKey(goal.minute)
        scorer = goal.scorer
        type = goal.type
        self.flag = flag
        self.isHome = isHome
    }

    /// Direct initializer for constructing rows outside the view model — e.g.
    /// SwiftUI previews of the Champion highlights.
    public init(id: String, minute: String, scorer: String, type: GoalType,
                flag: String, isHome: Bool) {
        self.id = id
        self.minute = minute
        self.sortKey = Self.sortKey(minute)
        self.scorer = scorer
        self.type = type
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

// MARK: - Standings presentation

public struct StandingsGroup: Identifiable {
    public let name: String
    public let rows: [StandingRowModel]

    public var id: String { name }

    public var title: String {
        if name.hasPrefix("Group "), let letter = name.split(separator: " ").last {
            return String(localized: "Group \(String(letter))", bundle: .module)
        }
        return name
    }
}

/// One standings row, resolved for display.
public struct StandingRowModel: Identifiable {
    public let id: String
    public let rank: Int
    public let teamID: String?
    public let flag: String
    public let name: String
    public let played: Int
    public let goalDifference: Int
    public let points: Int
    public let form: String
    public let qualification: String?

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

    public var qualifies: Bool { qualification != nil }

    /// Localized qualification label; reuses the stage names where they match.
    public var qualificationLabel: String? {
        guard let qualification else { return nil }
        return Stage(rawValue: qualification)?.displayName ?? qualification
    }
}

// MARK: - Champion presentation

/// The tournament winner, resolved for the celebratory Champion screen: who
/// lifted the trophy, the Final scoreline (champion first), and the goals that
/// decided it. Built by `MatchScheduleViewModel.champion` from the finished
/// Final and its goal timeline.
public struct ChampionModel: Identifiable {
    /// Champion Team record ID — the link target for the team detail screen.
    public let teamID: String
    public let name: String
    public let flag: String
    public let runnerUpName: String
    public let runnerUpFlag: String
    /// Final scoreline, champion first. After-extra-time score when it went long.
    public let score: Int?
    public let runnerUpScore: Int?
    /// Shootout scores, non-nil only for a Final settled on penalties.
    public let penaltyScore: Int?
    public let runnerUpPenaltyScore: Int?
    public let decidedBy: DecidedBy?
    public let venue: String
    public let finalMatchID: String
    /// Goals scored in the Final, minute-ordered — the celebration highlights.
    public let highlights: [GoalRowModel]

    public init(
        teamID: String,
        name: String,
        flag: String,
        runnerUpName: String,
        runnerUpFlag: String,
        score: Int?,
        runnerUpScore: Int?,
        penaltyScore: Int?,
        runnerUpPenaltyScore: Int?,
        decidedBy: DecidedBy?,
        venue: String,
        finalMatchID: String,
        highlights: [GoalRowModel]
    ) {
        self.teamID = teamID
        self.name = name
        self.flag = flag
        self.runnerUpName = runnerUpName
        self.runnerUpFlag = runnerUpFlag
        self.score = score
        self.runnerUpScore = runnerUpScore
        self.penaltyScore = penaltyScore
        self.runnerUpPenaltyScore = runnerUpPenaltyScore
        self.decidedBy = decidedBy
        self.venue = venue
        self.finalMatchID = finalMatchID
        self.highlights = highlights
    }

    public var id: String { teamID }

    /// True when the Final was settled by a shootout (both shootout scores set).
    public var wentToPenalties: Bool {
        penaltyScore != nil && runnerUpPenaltyScore != nil
    }
}

// MARK: - Team / squad presentation

public struct TeamRowModel: Identifiable {
    public let id: String
    public let name: String
    public let code: String
    public let flag: String
    public let group: String

    init(_ team: Team) {
        id = team.id
        name = team.name
        code = team.code
        flag = team.flag
        group = team.group
    }
}

/// One of a team's matches, seen from that team's side: the opponent, the
/// scoreline (this team first), and whether they won — for the results list on
/// the team detail screen. Built from a resolved `MatchRowModel` plus the team
/// whose page is being shown.
public struct TeamMatchRowModel: Identifiable {
    public enum Outcome: Sendable { case win, draw, loss }

    /// Match record ID — also the link target for the match detail screen.
    public let id: String
    public let kickoff: Date
    public let stage: Stage
    public let status: MatchStatus
    public let opponentFlag: String
    public let opponentName: String
    /// Scoreline from this team's perspective.
    public let teamScore: Int?
    public let opponentScore: Int?
    /// Shootout scores (this team first); non-nil only for a tie on penalties.
    public let teamPenalties: Int?
    public let opponentPenalties: Int?
    public let decidedBy: DecidedBy?
    /// The result from this team's perspective; nil until the match is finished.
    public let outcome: Outcome?

    init(row: MatchRowModel, teamID: String) {
        let isHome = row.home.teamID == teamID
        let team = isHome ? row.home : row.away
        let opponent = isHome ? row.away : row.home
        id = row.id
        kickoff = row.kickoff
        stage = row.stage
        status = row.status
        opponentFlag = opponent.flag
        opponentName = opponent.name
        teamScore = team.score
        opponentScore = opponent.score
        teamPenalties = team.penaltyScore
        opponentPenalties = opponent.penaltyScore
        decidedBy = row.decidedBy
        if row.status == .finished {
            outcome = row.didWin(team) ? .win : (row.didWin(opponent) ? .loss : .draw)
        } else {
            outcome = nil
        }
    }

    /// Whether both sides carry a shootout score, so the tie went to penalties.
    public var wentToPenalties: Bool {
        teamPenalties != nil && opponentPenalties != nil
    }
}

public struct SquadLineSection: Identifiable {
    public let position: PlayerPosition?
    public let members: [SquadRowModel]

    public var id: String { position?.rawValue ?? "other" }
    var sortOrder: Int { position?.sortOrder ?? 99 }
    public var title: String { position?.displayName ?? String(localized: "Squad", bundle: .module) }
}

public struct SquadRowModel: Identifiable {
    public let id: String
    public let number: Int?
    public let name: String
    public let age: Int?

    init(_ member: SquadMember) {
        id = member.id
        number = member.number
        name = member.player
        age = member.age
    }
}
