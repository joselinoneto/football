import SwiftUI
import FootballCore

/// Match detail: a scoreboard plus the live goal timeline. Reads its model from
/// the schedule view model by ID, so polling updates flow through while open.
struct MatchDetailView: View {
    let viewModel: MatchScheduleViewModel
    let matchID: String

    var body: some View {
        ScrollView {
            if let detail = viewModel.detail(for: matchID) {
                VStack(spacing: Design.Spacing.section) {
                    Scoreboard(row: detail.row)
                    GoalTimeline(row: detail.row, goals: detail.goals)
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

        return HStack(spacing: Design.Spacing.xLarge) {
            Text(side.flag.isEmpty ? "—" : side.flag)
                .font(.largeTitle)
                .frame(width: Design.Size.flagColumn, alignment: .center)
            Text(side.name)
                .font(.title3)
                .fontWeight(won ? .semibold : .regular)
                .foregroundStyle(decided && !lost ? .primary : .secondary)
                .lineLimit(1)
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

// MARK: - Goal timeline

private struct GoalTimeline: View {
    let row: MatchRowModel
    let goals: [GoalRowModel]

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.large) {
            Text("Goals")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if goals.isEmpty {
                Text(emptyMessage)
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Design.Spacing.large)
            } else {
                VStack(spacing: Design.Spacing.xLarge) {
                    ForEach(goals) { goal in
                        GoalRow(goal: goal)
                    }
                }
            }
        }
        .padding(Design.Spacing.section)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Design.Radius.card))
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
        HStack(spacing: Design.Spacing.xLarge) {
            Text(goal.minute)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: Design.Size.goalMinuteColumn, alignment: .leading)
            Image(systemName: "soccerball")
                .font(.footnote)
                .foregroundStyle(Color.pitch)
            scorer
            Spacer(minLength: Design.Spacing.medium)
            if !goal.flag.isEmpty {
                Text(goal.flag).font(.title3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var scorer: some View {
        HStack(spacing: Design.Spacing.xSmall) {
            Text(goal.scorer)
                .font(.body)
                .lineLimit(1)
            if let tag = goal.type.shortTag {
                Text("(\(tag))")
                    .font(.caption.weight(.medium))
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
        MatchDetailView(
            viewModel: {
                let viewModel = MatchScheduleViewModel(service: PreviewFootballService())
                Task { await viewModel.start() }
                return viewModel
            }(),
            matchID: "recM2"
        )
    }
}
