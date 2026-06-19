import SwiftUI

extension Color {
    /// Brand / pitch-green accent. Mirrors the asset `AccentColor` so system
    /// controls and our own views stay in sync.
    static let pitch = Color.accentColor

    /// Attention color for in-progress matches. A touch warmer and softer than
    /// system red so a live indicator reads as "happening now" without shouting.
    static let live = Color(red: 0.85, green: 0.18, blue: 0.22)
}
