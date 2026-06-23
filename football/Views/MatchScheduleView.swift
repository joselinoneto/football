import SwiftUI
import FootballCore
import FootballPresentation

enum ScheduleSection: String, CaseIterable, Identifiable {
    case matches
    case standings

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .matches: "Matches"
        case .standings: "Standings"
        }
    }

    var icon: String {
        switch self {
        case .matches: "soccerball"
        case .standings: "list.number"
        }
    }
}

struct MatchScheduleView: View {
    @State var viewModel: MatchScheduleViewModel
    @State private var section: ScheduleSection = .matches
    // "-ShowAbout" is passed by screenshot automation to open the sheet
    // without UI interaction; never set in normal use.
    @State private var showingAbout = ProcessInfo.processInfo.arguments.contains("-ShowAbout")

    var body: some View {
        NavigationStack {
            content
                .background(AppBackground())
                .navigationTitle("Football 2026")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("About", systemImage: "info.circle") {
                            showingAbout = true
                        }
                    }
                }
                .sheet(isPresented: $showingAbout) {
                    AboutView()
                }
                .sheet(isPresented: deepLinkBinding) {
                    if let id = viewModel.deepLinkedMatchID {
                        NavigationStack {
                            MatchDetailView(viewModel: viewModel, matchID: id)
                                .toolbar {
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button("Done") { viewModel.deepLinkedMatchID = nil }
                                    }
                                }
                        }
                    }
                }
        }
        .task {
            await viewModel.start()
        }
    }

    /// Drives the deep-link detail sheet opened from the widget / Live Activity.
    private var deepLinkBinding: Binding<Bool> {
        Binding(
            get: { viewModel.deepLinkedMatchID != nil },
            set: { if !$0 { viewModel.deepLinkedMatchID = nil } }
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
            VStack(spacing: 0) {
                SectionSwitcher(selection: $section)
                    .padding(.horizontal)
                    .padding(.top, Design.Spacing.medium)

                switch section {
                case .matches:
                    filterBar
                    matchList
                case .standings:
                    StandingsList(viewModel: viewModel)
                }
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

/// The Schedule / Standings switcher: two big, tappable segments on a Liquid
/// Glass track, with a tinted brand-green pill that springs between them as the
/// selection changes.
private struct SectionSwitcher: View {
    @Binding var selection: ScheduleSection
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ScheduleSection.allCases) { section in
                let isSelected = selection == section
                Button {
                    withAnimation(.bouncy(duration: 0.45)) { selection = section }
                } label: {
                    Label(section.title, systemImage: section.icon)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Design.Spacing.large)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color.pitch.gradient)
                                    .shadow(color: Color.pitch.opacity(0.35),
                                            radius: 8, y: 2)
                                    .matchedGeometryEffect(id: "selection", in: pill)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Design.Spacing.xSmall)
        .glassEffect(.regular, in: .capsule)
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
    MatchScheduleView(
        viewModel: MatchScheduleViewModel(service: PreviewFootballService())
    )
}
