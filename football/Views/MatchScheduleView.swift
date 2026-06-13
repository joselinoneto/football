import SwiftUI
import FootballCore

struct MatchScheduleView: View {
    @State var viewModel: MatchScheduleViewModel
    // "-ShowAbout" is passed by screenshot automation to open the sheet
    // without UI interaction; never set in normal use.
    @State private var showingAbout = ProcessInfo.processInfo.arguments.contains("-ShowAbout")

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("World Cup 2026")
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
        }
        .task {
            await viewModel.start()
        }
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
            HStack(spacing: 8) {
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
            .padding(.horizontal)
            .padding(.vertical, 8)
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
            List {
                ForEach(viewModel.filteredDays) { day in
                    Section(day.title) {
                        ForEach(day.rows) { row in
                            MatchRowView(row: row)
                                .listRowBackground(
                                    row.status == .live ? Color.red.opacity(0.1) : nil
                                )
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.quinary),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MatchScheduleView(
        viewModel: MatchScheduleViewModel(service: PreviewFootballService())
    )
}
