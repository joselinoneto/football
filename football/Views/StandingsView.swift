import SwiftUI
import FootballCore

struct StandingsView: View {
    @State var viewModel: StandingsViewModel

    var body: some View {
        NavigationStack {
            content
                .background(AppBackground())
                .navigationTitle("Standings")
        }
        .task {
            await viewModel.start()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .loading:
            ProgressView("Loading standings…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView {
                Label("No Standings", systemImage: "tablecells")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await viewModel.refresh() } }
                    .buttonStyle(.borderedProminent)
            }
        case .loaded:
            List {
                ForEach(viewModel.groups) { group in
                    Section {
                        StandingsHeaderRow()
                            .listRowBackground(Color.clear)
                        ForEach(group.rows) { row in
                            StandingRow(row: row)
                                .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
                        }
                    } header: {
                        Text(group.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    } footer: {
                        if group.isThirdPlaceRanking {
                            Text("Ranking of the third-placed teams; the best eight advance.")
                                .font(.caption)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .refreshable { await viewModel.refresh() }
        }
    }
}

private struct StandingsHeaderRow: View {
    var body: some View {
        HStack(spacing: Design.Spacing.xLarge) {
            Text(verbatim: "#")
                .frame(width: Design.Size.standingRankColumn, alignment: .center)
            Text("Team")
            Spacer(minLength: Design.Spacing.medium)
            Text("P").frame(width: Design.Size.standingStatColumn, alignment: .trailing)
            Text("GD").frame(width: Design.Size.standingStatColumn, alignment: .trailing)
            Text("Pts").frame(width: Design.Size.standingPointsColumn, alignment: .trailing)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.tertiary)
        .textCase(.uppercase)
    }
}

private struct StandingRow: View {
    let row: StandingRowModel

    var body: some View {
        HStack(spacing: Design.Spacing.xLarge) {
            ZStack {
                if row.qualifies {
                    Capsule().fill(Color.pitch.opacity(0.18))
                }
                Text("\(row.rank)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(row.qualifies ? Color.pitch : .secondary)
            }
            .frame(width: Design.Size.standingRankColumn, height: Design.Size.standingRankColumn)

            Text(row.flag.isEmpty ? "—" : row.flag)
            Text(row.name)
                .font(.body)
                .lineLimit(1)
            Spacer(minLength: Design.Spacing.medium)
            Text("\(row.played)")
                .frame(width: Design.Size.standingStatColumn, alignment: .trailing)
                .foregroundStyle(.secondary)
            Text(row.goalDifference > 0 ? "+\(row.goalDifference)" : "\(row.goalDifference)")
                .frame(width: Design.Size.standingStatColumn, alignment: .trailing)
                .foregroundStyle(.secondary)
            Text("\(row.points)")
                .font(.body.weight(.semibold))
                .frame(width: Design.Size.standingPointsColumn, alignment: .trailing)
        }
        .font(.subheadline.monospacedDigit())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: Text {
        var label = "\(row.rank). \(row.name). \(row.points) points, "
            + "\(row.played) played, goal difference \(row.goalDifference)."
        if let qualification = row.qualificationLabel {
            label += " \(qualification)."
        }
        return Text(label)
    }
}

#Preview {
    StandingsView(viewModel: StandingsViewModel(service: PreviewFootballService()))
}
