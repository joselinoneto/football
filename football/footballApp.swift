import SwiftUI
import WidgetKit
import BackgroundTasks
import FootballCore
import FootballPresentation

@main
struct footballApp: App {
    /// Must match `BGTaskSchedulerPermittedIdentifiers` in Info.plist.
    static let refreshTaskID = "app.zeneto.football.refresh"

    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: MatchScheduleViewModel
    @State private var appearance = AppearanceStore()
    private let liveActivities = MatchLiveActivityManager()

    init() {
        let dependencies = AppDependencies.live()
        let vm = MatchScheduleViewModel(service: dependencies.service)
        // After every store reload: refresh the Home Screen widget and keep any
        // Live Activity in sync. Both stay entirely in the app target.
        let activities = liveActivities
        vm.onStoreReloaded = { days in
            WidgetCenter.shared.reloadAllTimelines()
            activities.sync(days: days)
        }
        _viewModel = State(initialValue: vm)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(viewModel: viewModel, appearance: appearance)
                .onOpenURL { url in
                    if let id = MatchDeepLink.matchID(from: url) {
                        viewModel.openMatch(id: id)
                    }
                }
        }
        // Schedule a background refresh whenever we leave the foreground, so the
        // store, widget, and Live Activity keep updating while the app is closed.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { Self.scheduleAppRefresh() }
        }
        // Runs when iOS grants a background slot: pull scores, then reschedule.
        // `refreshScores()` reloads from the store, which fires `onStoreReloaded`
        // → widget reload + Live Activity update.
        .backgroundTask(.appRefresh(Self.refreshTaskID)) {
            await viewModel.refreshScores()
            Self.scheduleAppRefresh()
        }
    }

    static func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskID)
        // A hint, not a guarantee — iOS decides the real timing from usage and
        // battery. Tighter than the widget's own cadence so a granted slot is
        // useful for live scores.
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
