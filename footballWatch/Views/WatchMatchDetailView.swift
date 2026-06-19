import SwiftUI
import FootballCore
import FootballPresentation

/// Match detail on the watch: a compact scoreboard plus the goal timeline. Reads
/// its model from the schedule view model by ID, so polling updates flow through
/// while the screen is open.
struct WatchMatchDetailView: View {
    let viewModel: MatchScheduleViewModel
    let matchID: String

    var body: some View {
        ScrollView {
            if let detail = viewModel.detail(for: matchID) {
                VStack(spacing: Design.Spacing.large) {
                    Scoreboard(row: detail.row)
                    GoalTimeline(row: detail.row, goals: detail.goals)
                }
            } else {
                ContentUnavailableView(
                    "Match Unavailable",
                    systemImage: "soccerball"
                )
            }
        }
        .navigationTitle(navigationTitle)
    }

    private var navigationTitle: String {
        guard let row = viewModel.detail(for: matchID)?.row else { return "" }
        return row.stage == .group ? "" : row.stage.displayName
    }
}

// MARK: - Scoreboard

private struct Scoreboard: View {
    let row: MatchRowModel

    var body: some View {
        VStack(spacing: Design.Spacing.medium) {
            teamLine(row.home, opponentScore: row.away.score)
            teamLine(row.away, opponentScore: row.home.score)
            statusLine
        }
        .padding(Design.Spacing.large)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Design.Spacing.large))
    }

    private func teamLine(_ side: MatchRowModel.Side, opponentScore: Int?) -> some View {
        let decided = !side.flag.isEmpty
        let won = row.status == .finished && (side.score ?? 0) > (opponentScore ?? 0)
        let lost = row.status == .finished && (side.score ?? 0) < (opponentScore ?? 0)

        return HStack(spacing: Design.Spacing.medium) {
            Text(side.flag.isEmpty ? "—" : side.flag)
                .font(.title3)
            Text(side.name)
                .font(.body)
                .fontWeight(won ? .semibold : .regular)
                .foregroundStyle(decided && !lost ? .primary : .secondary)
                .lineLimit(1)
            Spacer(minLength: Design.Spacing.xSmall)
            if row.status != .scheduled, let score = side.score {
                Text("\(score)")
                    .font(.title2.monospacedDigit())
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
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.live)
            }
        case .finished:
            Text("Full time")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        case .scheduled:
            Text(row.kickoff.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var liveText: String {
        if let minute = row.minute, !minute.isEmpty {
            return String(localized: "LIVE · \(minute)")
        }
        return String(localized: "LIVE")
    }
}

// MARK: - Goal timeline

private struct GoalTimeline: View {
    let row: MatchRowModel
    let goals: [GoalRowModel]

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.medium) {
            Text("Goals")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if goals.isEmpty {
                Text(emptyMessage)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Design.Spacing.medium)
            } else {
                ForEach(goals) { goal in
                    GoalRow(goal: goal)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyMessage: String {
        switch row.status {
        case .scheduled: String(localized: "The match hasn't kicked off yet.")
        default: String(localized: "No goals yet.")
        }
    }
}

private struct GoalRow: View {
    let goal: GoalRowModel

    var body: some View {
        HStack(spacing: Design.Spacing.medium) {
            Text(goal.minute)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: Design.Size.flagColumn, alignment: .leading)
            if !goal.flag.isEmpty {
                Text(goal.flag).font(.body)
            }
            scorer
            Spacer(minLength: Design.Spacing.xSmall)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var scorer: some View {
        HStack(spacing: Design.Spacing.xxSmall) {
            Text(goal.scorer)
                .font(.footnote)
                .lineLimit(1)
            if let tag = goal.type.shortTag {
                Text("(\(tag))")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var accessibilityLabel: Text {
        if let tag = goal.type.shortTag {
            return Text("\(goal.minute) \(goal.scorer), \(goal.type.displayName) (\(tag))")
        }
        return Text("\(goal.minute) \(goal.scorer)")
    }
}

#Preview {
    NavigationStack {
        WatchMatchDetailView(
            viewModel: {
                let viewModel = MatchScheduleViewModel(service: PreviewFootballService())
                Task { await viewModel.start() }
                return viewModel
            }(),
            matchID: "recM2"
        )
    }
}
