import SwiftUI

struct MatchScheduleView: View {
    @State var viewModel: MatchScheduleViewModel
    @State private var showingAbout = false

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
            List {
                ForEach(viewModel.days) { day in
                    Section(day.title) {
                        ForEach(day.rows) { row in
                            MatchRowView(row: row)
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

#Preview {
    MatchScheduleView(
        viewModel: MatchScheduleViewModel(service: PreviewFootballService())
    )
}
