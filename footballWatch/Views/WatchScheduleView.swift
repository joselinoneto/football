import SwiftUI
import FootballCore
import FootballPresentation

/// The watch schedule: matches grouped by day in a List, each pushing a detail
/// screen. Shares the iOS polling view model, so live scores and the match
/// clock update on their own while the screen is open.
struct WatchScheduleView: View {
    @State var viewModel: MatchScheduleViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Football 2026")
        }
        .task {
            await viewModel.start()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ScrollView {
                ContentUnavailableView {
                    Label("No Matches", systemImage: "soccerball")
                } description: {
                    Text(message)
                }
            }
        case .loaded:
            matchList
        }
    }

    @ViewBuilder
    private var matchList: some View {
        if viewModel.days.isEmpty {
            ContentUnavailableView(
                "No Matches",
                systemImage: "soccerball"
            )
        } else {
            List {
                ForEach(viewModel.days) { day in
                    Section {
                        ForEach(day.rows) { row in
                            NavigationLink {
                                WatchMatchDetailView(viewModel: viewModel, matchID: row.id)
                            } label: {
                                WatchMatchRowView(row: row)
                            }
                            .listRowBackground(rowBackground(for: row))
                        }
                    } header: {
                        DayHeader(day: day)
                    }
                }
            }
            .listStyle(.carousel)
        }
    }

    @ViewBuilder
    private func rowBackground(for row: MatchRowModel) -> some View {
        RoundedRectangle(cornerRadius: Design.Spacing.large)
            .fill(row.status == .live
                  ? AnyShapeStyle(Color.live.opacity(Design.Opacity.liveRowTint))
                  : AnyShapeStyle(.regularMaterial))
    }
}

private struct DayHeader: View {
    let day: MatchDay

    var body: some View {
        HStack(spacing: Design.Spacing.small) {
            if day.isToday {
                Circle()
                    .fill(Color.pitch)
                    .frame(width: Design.Size.todayDot, height: Design.Size.todayDot)
            }
            Text(day.title)
                .font(.headline)
                .foregroundStyle(day.isToday ? Color.pitch : .primary)
        }
        .textCase(nil)
    }
}

#Preview {
    WatchScheduleView(
        viewModel: MatchScheduleViewModel(service: PreviewFootballService())
    )
}
