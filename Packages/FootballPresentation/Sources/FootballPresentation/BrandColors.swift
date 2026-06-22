#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Brand colors shared by every surface — the app, the Watch app, the Home
/// Screen widget, and the Live Activity — so the look stays identical across
/// processes. The numeric `Design.*` tokens live in `DesignSystem.swift`; these
/// need SwiftUI's `Color`, so they live here behind a `canImport` guard.
public extension Color {
    /// Brand / pitch-green accent. An *explicit* color rather than
    /// `Color.accentColor`, because in a widget or Live Activity extension the
    /// system accent falls back to blue — this keeps the brand green everywhere.
    /// Mirrors the `AccentColor` asset: a deep green in light mode, brighter in dark.
    static let pitch: Color = {
        #if os(watchOS)
        // watchOS renders on a dark background — use the brighter variant.
        return Color(.sRGB, red: 0.235, green: 0.804, blue: 0.420, opacity: 1)
        #elseif canImport(UIKit)
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.235, green: 0.804, blue: 0.420, alpha: 1)
                : UIColor(red: 0.043, green: 0.533, blue: 0.282, alpha: 1)
        })
        #else
        return Color(.sRGB, red: 0.043, green: 0.533, blue: 0.282, opacity: 1)
        #endif
    }()

    /// Attention color for in-progress matches. A touch warmer and softer than
    /// system red so a tinted row reads as "happening now" without shouting.
    static let live = Color(.sRGB, red: 0.85, green: 0.18, blue: 0.22, opacity: 1)
}
#endif
