import SwiftUI
import WidgetKit
import FootballCore
import FootballPresentation

/// Holds the user's favorite team and drives the app's brand color. Selecting a
/// team derives its color from the flag (`FlagPalette`), persists it to the
/// shared App Group (`BrandColorStore`) so `Color.pitch` — and therefore the
/// whole app, the widget, and the Live Activity — adopts it, and reloads the
/// widget timelines.
@MainActor
@Observable
final class AppearanceStore {
    private(set) var favoriteTeamID: String?

    init() {
        favoriteTeamID = BrandColorStore.favoriteTeamID
    }

    /// Changes whenever the favorite changes; `RootTabView` keys the UI on this
    /// so every surface re-reads the new `Color.pitch`.
    var brandToken: String { favoriteTeamID ?? "default" }

    func setFavorite(_ team: Team) {
        guard let color = FlagPalette.brandColor(forFlagEmoji: team.flag) else {
            clearFavorite()
            return
        }
        BrandColorStore.save(teamID: team.id, light: color.light, dark: color.dark)
        favoriteTeamID = team.id
        WidgetCenter.shared.reloadAllTimelines()
    }

    func clearFavorite() {
        BrandColorStore.clear()
        favoriteTeamID = nil
        WidgetCenter.shared.reloadAllTimelines()
    }
}
