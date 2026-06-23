import SwiftUI
import FootballPresentation

// Brand colors (`Color.pitch`, `Color.live`) are defined once in
// FootballPresentation so the app, Watch app, and widget share them.

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
