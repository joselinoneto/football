import SwiftUI
import FootballCore
import FootballPresentation

/// The Matches tab's "Future Games" segment: the upcoming, not-yet-played
/// fixtures shown as larger cards (rather than the compact Home-tab rows),
/// grouped by day in soonest-first order.
struct FutureGamesView: View {
    let viewModel: MatchScheduleViewModel

    /// Days reduced to only their scheduled (future) matches; days that end up
    /// empty are dropped. `viewModel.days` already orders upcoming days
    /// soonest-first, so the result reads as a forward schedule.
    private var futureDays: [MatchDay] {
        viewModel.days.compactMap { $0.keepingRows { $0.status == .scheduled } }
    }

    var body: some View {
        if futureDays.isEmpty {
            ContentUnavailableView(
                "No Upcoming Matches",
                systemImage: "calendar",
                description: Text("There are no future matches scheduled.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Design.Spacing.section) {
                    ForEach(futureDays) { day in
                        VStack(alignment: .leading, spacing: Design.Spacing.large) {
                            DayHeader(day: day)
                            ForEach(day.rows) { row in
                                NavigationLink {
                                    MatchDetailView(viewModel: viewModel, matchID: row.id)
                                } label: {
                                    FutureMatchCard(row: row)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, Design.Spacing.large)
                .padding(.bottom, Design.Spacing.screenBottom)
            }
            .scrollIndicators(.hidden)
            .refreshable { await viewModel.refresh() }
        }
    }
}

private struct DayHeader: View {
    let day: MatchDay

    var body: some View {
        HStack(spacing: Design.Spacing.medium) {
            if day.isToday {
                Circle()
                    .fill(Color.pitch)
                    .frame(width: Design.Size.todayDot, height: Design.Size.todayDot)
            }
            Text(day.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(day.isToday ? Color.pitch : .secondary)
            Spacer()
        }
    }
}

/// One upcoming fixture as a card: the round (for knockout ties), kickoff time,
/// both sides with large flags, and the venue.
private struct FutureMatchCard: View {
    let row: MatchRowModel

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.xLarge) {
            header
            VStack(spacing: Design.Spacing.large) {
                teamLine(row.home)
                teamLine(row.away)
            }
            venue
        }
        .padding(Design.Spacing.section)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: Design.Radius.card)
        )
        .contentShape(RoundedRectangle(cornerRadius: Design.Radius.card))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var header: some View {
        HStack {
            if row.stage != .group {
                Text(row.stage.displayName)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.pitch)
            }
            Spacer(minLength: 0)
            Text(row.kickoff, style: .time)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func teamLine(_ side: MatchRowModel.Side) -> some View {
        HStack(spacing: Design.Spacing.xLarge) {
            Text(side.flag.isEmpty ? "—" : side.flag)
                .font(.largeTitle)
                .frame(width: Design.Size.flagColumn, alignment: .center)
            Text(side.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(side.flag.isEmpty ? .secondary : .primary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    private var venue: some View {
        HStack(spacing: Design.Spacing.small) {
            Image(systemName: "mappin.and.ellipse")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(row.venue)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var accessibilityLabel: Text {
        let when = row.kickoff.formatted(date: .abbreviated, time: .shortened)
        let detail = row.stage == .group ? row.venue : "\(row.stage.displayName), \(row.venue)"
        return Text("\(row.home.name) versus \(row.away.name). \(when). \(detail)")
    }
}

#Preview {
    NavigationStack {
        FutureGamesView(
            viewModel: MatchScheduleViewModel(service: PreviewFootballService())
        )
        .background(AppBackground())
    }
}
