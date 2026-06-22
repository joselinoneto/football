import SwiftUI
import FootballPresentation

@main
struct footballWatchApp: App {
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            WatchScheduleView(
                viewModel: MatchScheduleViewModel(service: dependencies.service)
            )
        }
    }
}
