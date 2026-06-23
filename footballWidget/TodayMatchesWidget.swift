import WidgetKit
import SwiftUI
import FootballCore
import FootballPresentation

/// The Home Screen widget: today's games by default, or a chosen team's match.
/// Available in all three system sizes.
struct TodayMatchesWidget: Widget {
    let kind = "TodayMatchesWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectTeamIntent.self, provider: WidgetMatchProvider()) { entry in
            TodayMatchesEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Matches")
        .description("Today's games at a glance, or follow a team.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TodayMatchesEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MatchEntry

    var body: some View {
        switch family {
        case .systemSmall: SmallMatchView(entry: entry)
        case .systemLarge: LargeMatchView(entry: entry)
        default: MediumMatchView(entry: entry)
        }
    }
}

// MARK: - Shared pieces

private struct WidgetHeader: View {
    let title: String
    let hasLive: Bool

    var body: some View {
        HStack(spacing: Design.Spacing.small) {
            if hasLive {
                Circle()
                    .fill(Color.live)
                    .frame(width: Design.Size.liveDot, height: Design.Size.liveDot)
            } else {
                Image(systemName: "soccerball")
                    .font(.caption2)
                    .foregroundStyle(Color.pitch)
            }
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(hasLive ? Color.live : Color.pitch)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }
}

private struct WidgetEmpty: View {
    var body: some View {
        VStack(spacing: Design.Spacing.small) {
            Image(systemName: "soccerball")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("No matches today")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Small (single match)

private struct SmallMatchView: View {
    let entry: MatchEntry

    private var match: WidgetMatch? { entry.primaryMatch }

    var body: some View {
        if let match {
            VStack(alignment: .leading, spacing: Design.Spacing.small) {
                WidgetHeader(title: entry.primaryTitle, hasLive: match.status == .live)
                Spacer(minLength: 0)
                bigTeamLine(match.home, opponentScore: match.away.score, status: match.status)
                bigTeamLine(match.away, opponentScore: match.home.score, status: match.status)
                Spacer(minLength: 0)
                HStack {
                    Text(stageLabel(match))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                    Spacer(minLength: Design.Spacing.small)
                    WidgetStatusBadge(match: match)
                }
            }
            .widgetURL(MatchDeepLink.url(matchID: match.id))
        } else {
            WidgetEmpty()
        }
    }

    private func bigTeamLine(_ side: WidgetSide, opponentScore: Int?, status: MatchStatus) -> some View {
        let won = status == .finished && (side.score ?? 0) > (opponentScore ?? 0)
        let lost = status == .finished && (side.score ?? 0) < (opponentScore ?? 0)
        return HStack(spacing: Design.Spacing.medium) {
            Text(side.flag.isEmpty ? "—" : side.flag)
                .font(.title3)
            Text(side.code)
                .font(.headline)
                .foregroundStyle(lost ? .secondary : .primary)
            Spacer(minLength: Design.Spacing.small)
            if match?.showsScore == true, let score = side.score {
                Text("\(score)")
                    .font(.title2.monospacedDigit())
                    .fontWeight(won ? .bold : .medium)
                    .foregroundStyle(lost ? .secondary : .primary)
                    .contentTransition(.numericText())
            }
        }
    }

    private func stageLabel(_ match: WidgetMatch) -> String {
        guard match.stage == .group else { return match.stage.displayName }
        // "Group A" / "Grupo A" — append the letter when the teams are known.
        let group = String(localized: "Group")
        return match.group.map { "\(group) \($0)" } ?? group
    }
}

// MARK: - Medium (a few matches)

private struct MediumMatchView: View {
    let entry: MatchEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.small) {
            WidgetHeader(title: entry.title, hasLive: entry.hasLive)
            if entry.matches.isEmpty {
                WidgetEmpty()
            } else {
                ForEach(entry.matches.prefix(3)) { match in
                    Link(destination: MatchDeepLink.url(matchID: match.id)) {
                        WidgetMatchRow(match: match)
                    }
                }
                if entry.matches.count > 3 {
                    Text("+\(entry.matches.count - 3) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Large (full list)

private struct LargeMatchView: View {
    let entry: MatchEntry
    private let limit = 7

    /// Today first, then upcoming days, capped at `limit` matches total.
    private var sections: [WidgetDay] {
        var remaining = limit
        var out: [WidgetDay] = []
        for day in entry.days where !day.matches.isEmpty {
            guard remaining > 0 else { break }
            let slice = Array(day.matches.prefix(remaining))
            out.append(WidgetDay(date: day.date, title: day.title, matches: slice))
            remaining -= slice.count
        }
        return out
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.small) {
            if sections.isEmpty {
                WidgetHeader(title: entry.title, hasLive: entry.hasLive)
                WidgetEmpty()
            } else {
                ForEach(sections) { day in
                    WidgetHeader(title: day.title, hasLive: day.hasLive)
                    ForEach(day.matches) { match in
                        Link(destination: MatchDeepLink.url(matchID: match.id)) {
                            WidgetMatchRow(match: match)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}
