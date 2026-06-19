import SwiftUI
import FootballCore

struct TeamsListView: View {
    @State var viewModel: TeamsViewModel

    var body: some View {
        NavigationStack {
            content
                .background(AppBackground())
                .navigationTitle("Teams")
        }
        .task {
            await viewModel.start()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .loading:
            ProgressView("Loading teams…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView {
                Label("No Teams", systemImage: "person.3")
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
                        ForEach(group.teams) { team in
                            NavigationLink {
                                TeamDetailView(viewModel: viewModel, teamID: team.id)
                            } label: {
                                TeamRow(team: team)
                            }
                            .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
                        }
                    } header: {
                        Text(group.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .refreshable { await viewModel.refresh() }
        }
    }
}

private struct TeamRow: View {
    let team: TeamRowModel

    var body: some View {
        HStack(spacing: Design.Spacing.xLarge) {
            Text(team.flag.isEmpty ? "—" : team.flag)
                .font(.title3)
                .frame(width: Design.Size.flagColumn, alignment: .center)
            Text(team.name)
                .font(.body)
                .lineLimit(1)
            Spacer(minLength: Design.Spacing.medium)
            Text(team.code)
                .font(.caption.weight(.semibold).monospaced())
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    TeamsListView(viewModel: TeamsViewModel(service: PreviewFootballService()))
}
