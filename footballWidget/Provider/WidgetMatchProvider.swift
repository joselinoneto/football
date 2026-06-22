import Foundation
import WidgetKit
import FootballCore
import FootballManager

// MARK: - Display models

/// One side of a widget match row: flag, three-letter code, score.
struct WidgetSide {
    let teamID: String?
    let flag: String
    let code: String
    let score: Int?
}

extension WidgetSide {
    init(teamID: String?, score: Int?, fallback: String?, teamsByID: [String: Team]) {
        if let teamID, let team = teamsByID[teamID] {
            self.init(teamID: teamID, flag: team.flag, code: team.code, score: score)
        } else {
            // Undecided knockout slot (e.g. "Winner Match 74") — no flag yet.
            let code = fallback.map { String($0.prefix(3)).uppercased() } ?? "—"
            self.init(teamID: nil, flag: "", code: code, score: score)
        }
    }
}

struct WidgetMatch: Identifiable {
    let id: String
    let kickoff: Date
    let stage: Stage
    let venue: String
    let status: MatchStatus
    let minute: String?
    let home: WidgetSide
    let away: WidgetSide

    init(match: Match, teamsByID: [String: Team]) {
        id = match.id
        kickoff = match.kickoff
        stage = match.stage
        venue = match.venue
        status = match.status
        minute = match.minute
        home = WidgetSide(teamID: match.homeTeamID, score: match.homeScore,
                          fallback: match.titleSides?.home, teamsByID: teamsByID)
        away = WidgetSide(teamID: match.awayTeamID, score: match.awayScore,
                          fallback: match.titleSides?.away, teamsByID: teamsByID)
    }

    var showsScore: Bool { status != .scheduled }
    var teamIDs: [String] { [home.teamID, away.teamID].compactMap { $0 } }
}

// MARK: - Timeline entry

/// A day's worth of matches with its display title ("Today" or a date label).
struct WidgetDay: Identifiable {
    let date: Date
    let title: String
    let matches: [WidgetMatch]

    var id: Date { date }
    var hasLive: Bool { matches.contains { $0.status == .live } }
}

struct MatchEntry: TimelineEntry {
    let date: Date
    /// Title of the first day — "Today", a team name, or a date label.
    let title: String
    /// Matches grouped by day: today (or the next day with games) first, then
    /// upcoming days. The small and medium widgets show the first day; the large
    /// widget fills its space across days.
    let days: [WidgetDay]
    let hasLive: Bool

    /// The primary day's matches, for the small and medium widgets.
    var matches: [WidgetMatch] { days.first?.matches ?? [] }
}

// MARK: - Provider

struct WidgetMatchProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MatchEntry {
        MatchEntry(date: Date(), title: Self.todayTitle, days: [], hasLive: false)
    }

    func snapshot(for configuration: SelectTeamIntent, in context: Context) async -> MatchEntry {
        await Self.makeEntry(for: configuration, refresh: false)
    }

    func timeline(for configuration: SelectTeamIntent, in context: Context) async -> Timeline<MatchEntry> {
        let entry = await Self.makeEntry(for: configuration, refresh: true)
        // Tight cadence while a match is live so scores tick over; relaxed
        // otherwise. iOS coalesces and budgets these, so this is a hint.
        let interval: TimeInterval = entry.hasLive ? 60 : 30 * 60
        let next = Date().addingTimeInterval(interval)
        return Timeline(entries: [entry], policy: .after(next))
    }
}

// MARK: - Entry building

extension WidgetMatchProvider {
    static func makeEntry(for configuration: SelectTeamIntent, refresh: Bool) async -> MatchEntry {
        let service = WidgetDependencies.service
        // The widget can pull fresh scores itself (lightweight: Teams + Matches),
        // independent of the app being open.
        if refresh { try? await service.refreshScores() }

        let teams = (try? await service.teams()) ?? []
        let matches = (try? await service.matches()) ?? []
        let teamsByID = Dictionary(teams.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let all = matches.map { WidgetMatch(match: $0, teamsByID: teamsByID) }
        let now = Date()
        let calendar = Calendar.current

        // Configured for a specific team: show its most relevant match.
        if let team = configuration.team {
            let forTeam = all.filter { $0.teamIDs.contains(team.id) }
            let pick = relevantMatch(forTeam, now: now)
            let title = "\(team.flag) \(team.name)"
            let day = WidgetDay(
                date: calendar.startOfDay(for: pick?.kickoff ?? now),
                title: title,
                matches: pick.map { [$0] } ?? []
            )
            return MatchEntry(date: now, title: title, days: [day], hasLive: pick?.status == .live)
        }

        // Default: today's games first, then upcoming days (so the large widget
        // can show what's coming next once today's list runs out).
        let days = upcomingDays(all, now: now, calendar: calendar)
        return MatchEntry(
            date: now,
            title: days.first?.title ?? todayTitle,
            days: days,
            hasLive: days.first?.hasLive ?? false
        )
    }

    /// Groups today-or-later matches into days in chronological order. The day
    /// equal to today is titled "Today"; the rest get a weekday/date label.
    static func upcomingDays(_ all: [WidgetMatch], now: Date, calendar: Calendar) -> [WidgetDay] {
        let todayStart = calendar.startOfDay(for: now)
        let future = all
            .filter { calendar.startOfDay(for: $0.kickoff) >= todayStart }
            .sorted { $0.kickoff < $1.kickoff }

        var days: [WidgetDay] = []
        for match in future {
            let dayStart = calendar.startOfDay(for: match.kickoff)
            if let last = days.last, last.date == dayStart {
                days[days.count - 1] = WidgetDay(date: dayStart, title: last.title, matches: last.matches + [match])
            } else {
                let title = dayStart == todayStart ? todayTitle : dayTitle(match.kickoff)
                days.append(WidgetDay(date: dayStart, title: title, matches: [match]))
            }
        }
        return days
    }

    /// Live > next scheduled > most recent finished.
    static func relevantMatch(_ matches: [WidgetMatch], now: Date) -> WidgetMatch? {
        if let live = matches.first(where: { $0.status == .live }) { return live }
        if let next = matches
            .filter({ $0.kickoff >= now && $0.status == .scheduled })
            .sorted(by: { $0.kickoff < $1.kickoff }).first {
            return next
        }
        return matches.filter { $0.status == .finished }
            .max(by: { $0.kickoff < $1.kickoff })
            ?? matches.min(by: { $0.kickoff < $1.kickoff })
    }

    static var todayTitle: String { String(localized: "Today") }

    static func dayTitle(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }
}
