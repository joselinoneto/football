import SwiftUI
import FootballCore
import FootballPresentation

/// Home tab: the full schedule as a day-grouped, filterable match list. This is
/// the former `MatchScheduleView` content with the standings segment, the
/// section switcher, and the About entry point removed — those now live in the
/// Matches and Settings tabs.
struct MatchListView: View {
    let viewModel: MatchScheduleViewModel

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .loading:
            ProgressView("Loading matches…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView {
                Label("No Matches", systemImage: "soccerball")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.refresh() }
                }
                .buttonStyle(.borderedProminent)
            }
        case .loaded:
            VStack(spacing: 0) {
                filterBar
                matchList
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: Design.Spacing.medium) {
                HStack(spacing: Design.Spacing.medium) {
                    ForEach(MatchFilter.allCases) { filter in
                        FilterChip(
                            title: filter.title,
                            isSelected: viewModel.selectedFilter == filter
                        ) {
                            withAnimation(.snappy) {
                                viewModel.selectedFilter = filter
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Design.Spacing.medium)
        }
    }

    @ViewBuilder
    private var matchList: some View {
        if viewModel.filteredDays.isEmpty {
            ContentUnavailableView(
                "No Matches",
                systemImage: "soccerball",
                description: Text("There are no matches for this filter.")
            )
            .frame(maxHeight: .infinity)
        } else {
            matchListContent
        }
    }

    private var matchListContent: some View {
        List {
            ForEach(viewModel.filteredDays) { day in
                Section {
                    ForEach(day.rows) { row in
                        NavigationLink {
                            MatchDetailView(viewModel: viewModel, matchID: row.id)
                        } label: {
                            MatchRowView(row: row)
                        }
                        .listRowBackground(rowBackground(for: row))
                    }
                } header: {
                    DayHeader(day: day)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .refreshable {
            await viewModel.refresh()
        }
    }

    private func rowBackground(for row: MatchRowModel) -> some View {
        (row.status == .live ? Color.live.opacity(Design.Opacity.liveRowTint) : Color(uiColor: .secondarySystemGroupedBackground))
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
        .textCase(nil)
        .padding(.bottom, Design.Spacing.xxSmall)
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, Design.Spacing.xxxLarge)
                .padding(.vertical, Design.Spacing.medium)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected ? .regular.tint(Color.pitch).interactive() : .regular.interactive(),
            in: .capsule
        )
        .animation(.snappy, value: isSelected)
    }
}

#Preview {
    NavigationStack {
        MatchListView(
            viewModel: MatchScheduleViewModel(service: PreviewFootballService())
        )
        .background(AppBackground())
        .navigationTitle("Football 2026")
    }
}
