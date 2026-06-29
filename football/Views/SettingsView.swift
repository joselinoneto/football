import SwiftUI
import FootballCore
import FootballPresentation

/// Settings tab: a list of options. "Favorite team" picks a team whose flag
/// color becomes the app's accent; "About" shows the app info.
struct SettingsView: View {
    let viewModel: MatchScheduleViewModel
    let appearance: AppearanceStore

    var body: some View {
        List {
            Section {
                NavigationLink {
                    TeamPickerView(teams: viewModel.allTeams, appearance: appearance)
                } label: {
                    favoriteRow
                }
            } header: {
                Text("Appearance")
            } footer: {
                Text("Your favorite team's flag color becomes the app's accent.")
            }

            Section {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About", systemImage: "info.circle")
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var favoriteRow: some View {
        let team = viewModel.allTeams.first { $0.id == appearance.favoriteTeamID }
        return HStack(spacing: Design.Spacing.medium) {
            Label("Favorite team", systemImage: "star")
            Spacer(minLength: Design.Spacing.medium)
            if let team {
                Text(team.flag)
                Text(team.name)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("Default")
                    .foregroundStyle(.secondary)
            }
            Circle()
                .fill(Color.pitch)
                .frame(width: Design.Size.todayDot + 7, height: Design.Size.todayDot + 7)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            viewModel: MatchScheduleViewModel(service: PreviewFootballService()),
            appearance: AppearanceStore()
        )
        .background(AppBackground())
        .navigationTitle("Settings")
    }
}
