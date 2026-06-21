import SwiftUI
import FootballCore

/// Match detail: a scoreboard, the live goal/event timeline, team statistics,
/// and lineups. Reads its model from the schedule view model by ID, so polling
/// updates flow through while open.
struct MatchDetailView: View {
    let viewModel: MatchScheduleViewModel
    let matchID: String

    var body: some View {
        ScrollView {
            if let detail = viewModel.detail(for: matchID) {
                VStack(spacing: Design.Spacing.section) {
                    Scoreboard(row: detail.row, viewModel: viewModel)
                    TimelineCard(row: detail.row, items: detail.timeline)
                    if !detail.stats.isEmpty {
                        StatsCard(stats: detail.stats)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, Design.Spacing.section)
            } else {
                ContentUnavailableView(
                    "Match Unavailable",
                    systemImage: "soccerball",
                    description: Text("This match could not be loaded.")
                )
                .padding(.top, Design.Spacing.sectionLarge)
            }
        }
        .background(AppBackground())
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Scoreboard

private struct Scoreboard: View {
    let row: MatchRowModel
    let viewModel: MatchScheduleViewModel

    var body: some View {
        VStack(spacing: Design.Spacing.large) {
            context
            VStack(spacing: Design.Spacing.medium) {
                teamLine(row.home, opponentScore: row.away.score)
                teamLine(row.away, opponentScore: row.home.score)
            }
            statusLine
        }
        .padding(Design.Spacing.section)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Design.Radius.card))
    }

    private var context: some View {
        Text(row.stage == .group ? row.venue : "\(row.stage.displayName) · \(row.venue)")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    private func teamLine(_ side: MatchRowModel.Side, opponentScore: Int?) -> some View {
        let decided = !side.flag.isEmpty
        let won = row.status == .finished && (side.score ?? 0) > (opponentScore ?? 0)
        let lost = row.status == .finished && (side.score ?? 0) < (opponentScore ?? 0)

        let name = Text(side.name)
            .font(.title3)
            .fontWeight(won ? .semibold : .regular)
            .foregroundStyle(decided && !lost ? .primary : .secondary)
            .lineLimit(1)

        return HStack(spacing: Design.Spacing.xLarge) {
            Text(side.flag.isEmpty ? "—" : side.flag)
                .font(.largeTitle)
                .frame(width: Design.Size.flagColumn, alignment: .center)
            // Tapping a decided team opens its squad.
            if let teamID = side.teamID {
                NavigationLink {
                    TeamDetailView(viewModel: viewModel, teamID: teamID)
                } label: {
                    name
                }
                .buttonStyle(.plain)
            } else {
                name
            }
            Spacer(minLength: Design.Spacing.medium)
            if row.status != .scheduled, let score = side.score {
                Text("\(score)")
                    .font(.largeTitle.monospacedDigit())
                    .fontWeight(won ? .bold : .medium)
                    .foregroundStyle(lost ? .secondary : .primary)
                    .contentTransition(.numericText())
            }
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        switch row.status {
        case .live:
            HStack(spacing: Design.Spacing.small) {
                Circle()
                    .fill(Color.live)
                    .frame(width: Design.Size.liveDot, height: Design.Size.liveDot)
                Text(liveText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.live)
            }
        case .finished:
            Text("Full time")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        case .scheduled:
            Text(row.kickoff.formatted(date: .abbreviated, time: .shortened))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var liveText: String {
        if let minute = row.minute, !minute.isEmpty {
            return String(localized: "LIVE · \(minute)")
        }
        return String(localized: "LIVE")
    }
}

// MARK: - Section card

/// Shared section container matching the scoreboard card style.
private struct SectionCard<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.large) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content
        }
        .padding(Design.Spacing.section)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Design.Radius.card))
    }
}

// MARK: - Timeline

private struct TimelineCard: View {
    let row: MatchRowModel
    let items: [TimelineItemModel]

    var body: some View {
        SectionCard(title: "Timeline") {
            if items.isEmpty {
                Text(emptyMessage)
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Design.Spacing.large)
            } else {
                VStack(spacing: Design.Spacing.xLarge) {
                    ForEach(items) { item in
                        TimelineRow(item: item)
                    }
                }
            }
        }
    }

    private var emptyMessage: String {
        switch row.status {
        case .scheduled: String(localized: "The match hasn't kicked off yet.")
        default: String(localized: "Nothing to report yet.")
        }
    }
}

private struct TimelineRow: View {
    let item: TimelineItemModel

    var body: some View {
        HStack(spacing: Design.Spacing.xLarge) {
            Text(item.minute)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: Design.Size.goalMinuteColumn, alignment: .leading)
            glyph
            text
            Spacer(minLength: Design.Spacing.medium)
            if !item.flag.isEmpty {
                Text(item.flag).font(.title3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var glyph: some View {
        if item.goalType != nil {
            Image(systemName: "soccerball")
                .font(.footnote)
                .foregroundStyle(Color.pitch)
        } else if let eventType = item.eventType {
            Image(systemName: eventType.symbolName)
                .font(.footnote)
                .foregroundStyle(eventType.tint)
        }
    }

    private var text: some View {
        HStack(spacing: Design.Spacing.xSmall) {
            Text(item.primary)
                .font(.body)
                .lineLimit(1)
            if let secondary = item.secondary, !secondary.isEmpty {
                // Goal tag reads "(pen)"; a substitution reads "→ Player".
                Text(item.goalType != nil ? "(\(secondary))" : "→ \(secondary)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var accessibilityLabel: Text {
        let kind = item.goalType?.displayName ?? item.eventType?.displayName ?? ""
        var label = "\(item.minute) \(kind), \(item.primary)"
        if let secondary = item.secondary, !secondary.isEmpty { label += " \(secondary)" }
        return Text(label)
    }
}

// MARK: - Statistics

private struct StatsCard: View {
    let stats: MatchStatsModel

    var body: some View {
        SectionCard(title: "Match stats") {
            VStack(spacing: Design.Spacing.xLarge) {
                ForEach(stats.rows) { row in
                    StatComparisonView(row: row)
                }
            }
        }
    }
}

private struct StatComparisonView: View {
    let row: StatComparisonRow

    var body: some View {
        VStack(spacing: Design.Spacing.small) {
            HStack {
                Text(row.home)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                Spacer()
                Text(row.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(row.away)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }
            if let fraction = row.homeFraction {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        Capsule()
                            .fill(Color.pitch)
                            .frame(width: max(0, geo.size.width * fraction - 1))
                        Capsule()
                            .fill(Color.pitch.opacity(0.22))
                    }
                }
                .frame(height: Design.Size.statBarHeight)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MatchDetailView(
            viewModel: {
                let viewModel = MatchScheduleViewModel(service: PreviewFootballService())
                Task { await viewModel.start() }
                return viewModel
            }(),
            matchID: "recM1"
        )
    }
}
