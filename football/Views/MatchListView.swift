import SwiftUI
import FootballCore
import FootballPresentation

/// Home tab: the full schedule as a day-grouped, filterable match list. This is
/// the former `MatchScheduleView` content with the standings segment, the
/// section switcher, and the About entry point removed — those now live in the
/// Matches and Settings tabs.
struct MatchListView: View {
    let viewModel: MatchScheduleViewModel
    /// When set, the list is the primary pane of a split (iPhone Duo open):
    /// tapping a row selects it for the detail pane instead of pushing.
    var selection: Binding<String?>? = nil
    /// The match most recently opened by a push, so the host can carry it into
    /// the split pane when the device unfolds.
    var lastOpened: Binding<String?>? = nil

    var body: some View {
        content
            .toolbar {
                if case .loaded = viewModel.phase {
                    ToolbarItem(placement: .primaryAction) {
                        filterMenu
                    }
                }
            }
    }

    /// The day/upcoming/finished filter, as a top-bar dropdown so the schedule
    /// gets the full screen. The label shows the active filter.
    private var filterMenu: some View {
        Menu {
            Picker("Filter", selection: filterBinding) {
                ForEach(MatchFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
        } label: {
            HStack(spacing: Design.Spacing.xSmall) {
                Image(systemName: "line.3.horizontal.decrease")
                Text(viewModel.selectedFilter.title)
                    .fontWeight(.semibold)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
        }
    }

    private var filterBinding: Binding<MatchFilter> {
        Binding(
            get: { viewModel.selectedFilter },
            set: { newValue in withAnimation(.snappy) { viewModel.selectedFilter = newValue } }
        )
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
            matchList
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
            // Once the Final is played, crown the champions at the top of the
            // schedule with a tappable board into the dedicated Champion screen.
            if let champion = viewModel.champion {
                Section {
                    NavigationLink {
                        ChampionView(viewModel: viewModel, champion: champion)
                    } label: {
                        ChampionBanner(champion: champion)
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
                }
            }
            ForEach(viewModel.filteredDays) { day in
                Section {
                    ForEach(day.rows) { row in
                        matchRow(row)
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
        // Pushed match detail (rows in push mode carry the match ID as value).
        .navigationDestination(for: String.self) { matchID in
            MatchDetailView(viewModel: viewModel, matchID: matchID)
                .onAppear { lastOpened?.wrappedValue = matchID }
        }
    }

    @ViewBuilder
    private func matchRow(_ row: MatchRowModel) -> some View {
        if let selection {
            Button {
                withAnimation(.snappy) { selection.wrappedValue = row.id }
            } label: {
                HStack(spacing: Design.Spacing.medium) {
                    MatchRowView(row: row)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: row.id) {
                MatchRowView(row: row)
            }
        }
    }

    private func rowBackground(for row: MatchRowModel) -> some View {
        if selection?.wrappedValue == row.id {
            return Color.pitch.opacity(Design.Opacity.selectedRowTint)
        }
        return row.status == .live ? Color.live.opacity(Design.Opacity.liveRowTint) : Color(uiColor: .secondarySystemGroupedBackground)
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

#Preview {
    NavigationStack {
        MatchListView(
            viewModel: MatchScheduleViewModel(service: PreviewFootballService())
        )
        .background(AppBackground())
        .navigationTitle("Football 2026")
    }
}
