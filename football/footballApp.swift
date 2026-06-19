import SwiftUI
import FootballManager

@main
struct footballApp: App {
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootTabView(service: dependencies.service)
        }
    }
}

/// The app's four sections. Each tab owns its own view model over the shared
/// service; the schedule tab drives the polling that keeps the local store
/// fresh, and the other tabs reflect it.
private struct RootTabView: View {
    let service: any FootballService

    var body: some View {
        TabView {
            MatchScheduleView(viewModel: MatchScheduleViewModel(service: service))
                .tabItem { Label("Schedule", systemImage: "calendar") }
            StandingsView(viewModel: StandingsViewModel(service: service))
                .tabItem { Label("Standings", systemImage: "tablecells") }
            TopScorersView(viewModel: TopScorersViewModel(service: service))
                .tabItem { Label("Scorers", systemImage: "soccerball") }
            TeamsListView(viewModel: TeamsViewModel(service: service))
                .tabItem { Label("Teams", systemImage: "person.3") }
        }
    }
}
