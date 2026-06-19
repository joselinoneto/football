import SwiftUI
import FootballCore

struct TopScorersView: View {
    @State var viewModel: TopScorersViewModel

    var body: some View {
        NavigationStack {
            content
                .background(AppBackground())
                .navigationTitle("Top Scorers")
        }
        .task {
            await viewModel.start()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .loading:
            ProgressView("Loading scorers…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView {
                Label("No Scorers", systemImage: "soccerball")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await viewModel.refresh() } }
                    .buttonStyle(.borderedProminent)
            }
        case .loaded:
            List {
                ForEach(viewModel.scorers) { scorer in
                    ScorerRow(scorer: scorer)
                        .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .refreshable { await viewModel.refresh() }
        }
    }
}

private struct ScorerRow: View {
    let scorer: TopScorerRowModel

    var body: some View {
        HStack(spacing: Design.Spacing.xLarge) {
            Text("\(scorer.rank)")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(scorer.rank <= 3 ? Color.pitch : .secondary)
                .frame(width: Design.Size.rankBadge, alignment: .center)

            VStack(alignment: .leading, spacing: Design.Spacing.xxSmall) {
                Text(scorer.player)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: Design.Spacing.xSmall) {
                    if !scorer.flag.isEmpty { Text(scorer.flag).font(.caption) }
                    Text(scorer.teamName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: Design.Spacing.medium)
            goalsBadge
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var goalsBadge: some View {
        HStack(alignment: .firstTextBaseline, spacing: Design.Spacing.xSmall) {
            Text("\(scorer.goals)")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(Color.pitch)
            VStack(alignment: .leading, spacing: 0) {
                Text("goals")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if scorer.assists > 0 {
                    Text("\(scorer.assists) A")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var accessibilityLabel: Text {
        var label = "\(scorer.rank). \(scorer.player), \(scorer.teamName). \(scorer.goals) goals"
        if scorer.assists > 0 { label += ", \(scorer.assists) assists" }
        return Text(label + ".")
    }
}

#Preview {
    TopScorersView(viewModel: TopScorersViewModel(service: PreviewFootballService()))
}
