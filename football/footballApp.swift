import SwiftUI

@main
struct footballApp: App {
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            MatchScheduleView(
                viewModel: MatchScheduleViewModel(service: dependencies.service)
            )
        }
    }
}
