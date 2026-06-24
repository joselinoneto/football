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
    /// Group letter (A–L) for group-stage matches; nil for knockout games.
    let group: String?

    init(match: Match, teamsByID: [String: Team]) {
        id = match.id
        kickoff = match.kickoff
        stage = match.stage
        venue = match.venue
        status = match.status
        minute = match.minute
        // Both sides of a group game share a group letter; take it from
        // whichever team is already decided.
        group = match.stage == .group
            ? [match.homeTeamID, match.awayTeamID]
                .compactMap { $0 }
                .compactMap { teamsByID[$0]?.group }
                .first
            : nil
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
    /// The single most relevant match for the small widget: live now, else the
    /// next scheduled game (today or a future day), else the latest finished.
    let primaryMatch: WidgetMatch?
    /// Header title that goes with `primaryMatch` — its day ("Today"/weekday) or
    /// the followed team's name.
    let primaryTitle: String
    /// True when configured to follow one team — the medium/large widgets then
    /// show that team's recent results plus its upcoming games, not a day's list.
    let followsTeam: Bool

    /// The primary day's matches, for the medium widget.
    var matches: [WidgetMatch] { days.first?.matches ?? [] }
}

// MARK: - Provider

struct WidgetMatchProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MatchEntry {
        MatchEntry(date: Date(), title: Self.todayTitle, days: [], hasLive: false,
                   primaryMatch: nil, primaryTitle: Self.todayTitle, followsTeam: false)
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
        // The widget pulls fresh scores itself, independent of the app being
        // open. To spare the API, scope the network to what actually changed:
        // during the fast live cadence (60s) only the live/imminent matches move,
        // so one scoped request suffices (no Teams). On the relaxed cadence — or
        // a cold store — do the fuller Teams + Matches pull to pick up schedule
        // changes and final scores.
        var matches = (try? await service.matches()) ?? []
        if refresh {
            if matches.contains(where: { $0.status == .live }) {
                try? await service.refreshLiveScores()
            } else {
                try? await service.refreshScores()
            }
            matches = (try? await service.matches()) ?? []
        }

        let teams = (try? await service.teams()) ?? []
        let teamsByID = Dictionary(teams.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let all = matches.map { WidgetMatch(match: $0, teamsByID: teamsByID) }
        let now = Date()
        let calendar = Calendar.current

        // Configured for a specific team: the medium/large widgets show its
        // recent results then upcoming games; the small widget shows the single
        // most relevant match (live/next).
        if let team = configuration.team {
            let forTeam = all.filter { $0.teamIDs.contains(team.id) }
            let timeline = teamTimeline(forTeam, now: now)
            let pick = relevantMatch(forTeam, now: now)
            let title = "\(team.flag) \(team.name)"
            let day = WidgetDay(
                date: calendar.startOfDay(for: pick?.kickoff ?? now),
                title: title,
                matches: timeline
            )
            return MatchEntry(date: now, title: title, days: [day],
                              hasLive: timeline.contains { $0.status == .live },
                              primaryMatch: pick, primaryTitle: title, followsTeam: true)
        }

        // Default: today's games first, then upcoming days (so the large widget
        // can show what's coming next once today's list runs out).
        let days = upcomingDays(all, now: now, calendar: calendar)
        // The small widget tracks one match across all days, so it follows the
        // live or next-scheduled game rather than sticking on today's opener.
        let primary = relevantMatch(all, now: now)
        let primaryTitle = primary.map { dayHeader(for: $0.kickoff, now: now, calendar: calendar) } ?? todayTitle
        return MatchEntry(
            date: now,
            title: days.first?.title ?? todayTitle,
            days: days,
            hasLive: days.first?.hasLive ?? false,
            primaryMatch: primary,
            primaryTitle: primaryTitle,
            followsTeam: false
        )
    }

    /// A followed team's timeline: its last 3 results, then any live game, then
    /// upcoming fixtures in kickoff order. The widgets window this to fit.
    static func teamTimeline(_ matches: [WidgetMatch], now: Date) -> [WidgetMatch] {
        let sorted = matches.sorted { $0.kickoff < $1.kickoff }
        let recent = sorted.filter { $0.status == .finished }.suffix(3)
        let liveAndUpcoming = sorted.filter { $0.status != .finished }
        return Array(recent) + liveAndUpcoming
    }

    /// "Today" when the date is today, otherwise a weekday/date label.
    static func dayHeader(for date: Date, now: Date, calendar: Calendar) -> String {
        calendar.isDate(date, inSameDayAs: now) ? todayTitle : dayTitle(date)
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

    /// Picks a `limit`-sized window over an ordered timeline that keeps the
    /// next (first non-finished) match in view, backfilling with the most
    /// recent results before it.
    static func window(_ matches: [WidgetMatch], limit: Int) -> [WidgetMatch] {
        guard matches.count > limit else { return matches }
        let boundary = matches.firstIndex { $0.status != .finished } ?? matches.count
        let start = min(max(0, boundary - (limit - 1)), matches.count - limit)
        return Array(matches[start ..< start + limit])
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
