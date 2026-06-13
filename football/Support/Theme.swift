import SwiftUI

extension Color {
    /// Brand / pitch-green accent. Mirrors the asset `AccentColor` so system
    /// controls (buttons, switches, the tint) and our own views stay in sync.
    static let pitch = Color.accentColor

    /// Attention color for in-progress matches. A touch warmer and softer than
    /// system red so a tinted row reads as "happening now" without shouting.
    static let live = Color(red: 0.85, green: 0.18, blue: 0.22)
}

/// The schedule's canvas. A faint wash of the brand color at the top settles
/// into the standard grouped background, so the screen feels considered rather
/// than flat system gray — while rows stay on legible cards on top of it.
struct AppBackground: View {
    var body: some View {
        Color(uiColor: .systemGroupedBackground)
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.pitch.opacity(Design.Opacity.canvasWash), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: Design.Size.canvasWashHeight)
            }
            .ignoresSafeArea()
    }
}
