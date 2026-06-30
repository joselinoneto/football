import SwiftUI
import FootballCore
import FootballPresentation

/// The app's root: a three-tab layout. Home is the schedule, Matches holds the
/// upcoming fixtures and group-phase standings, and Settings carries the About
/// info. App-wide concerns that used to live on the schedule screen — the
/// refresh loop and the widget / Live-Activity deep-link sheet — live here so
/// they work regardless of the selected tab.
struct RootTabView: View {
    @State var viewModel: MatchScheduleViewModel
    var appearance: AppearanceStore
    @State private var selection: AppTab = .initialFromLaunchArguments

    private enum AppTab: Hashable {
        case home, matches, groupStage, settings

        /// Screenshot automation can land directly on a tab via a launch arg
        /// (e.g. "-ShowAbout" / "-ShowMatches"); never set in normal use.
        static var initialFromLaunchArguments: AppTab {
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-ShowAbout") || args.contains("-ShowSettings") { return .settings }
            if args.contains("-ShowMatches") { return .matches }
            if args.contains("-ShowGroupStage") { return .groupStage }
            return .home
        }
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                NavigationStack {
                    MatchListView(viewModel: viewModel)
                        .background(AppBackground())
                        .navigationTitle("Football 2026")
                }
            }
            Tab("Matches", systemImage: "soccerball", value: AppTab.matches) {
                NavigationStack {
                    KnockoutBracketView(viewModel: viewModel)
                        .navigationTitle("Matches")
                        .background(AppBackground())
                }
            }
            Tab("Group Stage", systemImage: "list.number", value: AppTab.groupStage) {
                NavigationStack {
                    StandingsList(viewModel: viewModel)
                        .background(AppBackground())
                        .navigationTitle("Group Stage")
                }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    SettingsView(viewModel: viewModel, appearance: appearance)
                        .background(AppBackground())
                        .navigationTitle("Settings")
                }
            }
        }
        // Rebuild the whole UI when the favorite team changes, so every brand
        // surface re-reads the now-team-colored `Color.pitch`.
        .id(appearance.brandToken)
        // Tint the selected tab with the brand accent (team color or green).
        .tint(Color.pitch)
        .task {
            await viewModel.start()
        }
        // Screenshot automation only: once data is loaded, apply launch-argument
        // overrides (pre-select a favorite team to show the themed accent, and
        // open a representative match's detail). Inert in normal use.
        .onChange(of: viewModel.days.isEmpty) { _, isEmpty in
            if !isEmpty { applyScreenshotLaunchArguments() }
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

    /// Screenshot automation only. `-SeedFavorite <CODE>` pre-selects a favorite
    /// team so screenshots show the team-tinted accent; `-ShowSampleMatch` opens a
    /// representative match's detail. Never set in normal use.
    private func applyScreenshotLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-SeedFavorite"), i + 1 < args.count,
           appearance.favoriteTeamID == nil,
           let team = viewModel.allTeams.first(where: { $0.code == args[i + 1] }) {
            appearance.setFavorite(team)
        }
        if args.contains("-ShowSampleMatch"), viewModel.deepLinkedMatchID == nil,
           let id = viewModel.sampleMatchID {
            viewModel.openMatch(id: id)
        }
    }

    /// Drives the deep-link detail sheet opened from the widget / Live Activity.
    private var deepLinkBinding: Binding<Bool> {
        Binding(
            get: { viewModel.deepLinkedMatchID != nil },
            set: { if !$0 { viewModel.deepLinkedMatchID = nil } }
        )
    }
}

#Preview {
    RootTabView(
        viewModel: MatchScheduleViewModel(service: PreviewFootballService()),
        appearance: AppearanceStore()
    )
}
