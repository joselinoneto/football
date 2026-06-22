import WidgetKit
import SwiftUI

@main
struct footballWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayMatchesWidget()
        MatchLiveActivityWidget()
    }
}
