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
    /// Brand accent. Defaults to pitch green but follows the user's favorite team
    /// when one is set (see `BrandColorStore`) — an *explicit* color rather than
    /// `Color.accentColor`, because in a widget or Live Activity the system accent
    /// falls back to blue. Every brand surface reads this, so the whole app and
    /// widget recolor from one place. Reading is cheap: the resolved color is
    /// cached and only rebuilt when the stored favorite changes.
    static var pitch: Color { BrandColorResolver.current }

    /// The brand green, ignoring any favorite override (for the "Default" swatch).
    static let pitchDefault: Color = {
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

/// Resolves `Color.pitch` from the stored favorite-team color, caching the built
/// `Color` so per-render reads don't rebuild it.
enum BrandColorResolver {
    // UI-thread access in practice; a race would only rebuild the Color, which is
    // harmless, so the unchecked mutable static is acceptable here.
    nonisolated(unsafe) private static var cache: (stored: BrandColorStore.Stored, color: Color)?

    static var current: Color {
        guard let stored = BrandColorStore.current() else { return .pitchDefault }
        if let cache, cache.stored == stored { return cache.color }
        let color = make(stored)
        cache = (stored, color)
        return color
    }

    private static func make(_ stored: BrandColorStore.Stored) -> Color {
        #if os(watchOS)
        return Color(.sRGB, red: stored.dark.red, green: stored.dark.green, blue: stored.dark.blue, opacity: 1)
        #elseif canImport(UIKit)
        return Color(uiColor: UIColor { traits in
            let v = traits.userInterfaceStyle == .dark ? stored.dark : stored.light
            return UIColor(red: v.red, green: v.green, blue: v.blue, alpha: 1)
        })
        #else
        return Color(.sRGB, red: stored.light.red, green: stored.light.green, blue: stored.light.blue, opacity: 1)
        #endif
    }
}
#endif
