import SwiftUI

/// App-wide design tokens. Every spacing, size, radius, opacity, and motion
/// value the UI uses lives here so the look stays consistent and can be tuned
/// from one place. Views should reference these instead of hard-coding numbers.
///
/// Brand colors live alongside this in `Theme.swift`.
enum Design {

    /// Spacing and padding on a 2-pt grid. Ordered small → large; the four
    /// `section*` steps are reserved for screen-level rhythm.
    enum Spacing {
        static let xxSmall: CGFloat = 2
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 10
        static let xLarge: CGFloat = 12
        static let xxLarge: CGFloat = 14
        static let xxxLarge: CGFloat = 16
        static let section: CGFloat = 24
        static let sectionLarge: CGFloat = 28
        static let screenBottom: CGFloat = 32
    }

    /// Corner radii for filled containers.
    enum Radius {
        static let card: CGFloat = 20
    }

    /// Fixed element dimensions that can't come from Dynamic Type.
    enum Size {
        /// Width of the flag column, so both team lines align.
        static let flagColumn: CGFloat = 30
        /// Width of the minute column in the goal timeline, so scorers align.
        static let goalMinuteColumn: CGFloat = 48
        /// Pulsing dot inside the LIVE badge.
        static let liveDot: CGFloat = 6
        /// Accent dot next to the "Today" section header.
        static let todayDot: CGFloat = 7
        /// About-screen icon glyph and the halo behind it.
        static let aboutGlyph: CGFloat = 78
        static let aboutHalo: CGFloat = 136
        /// Height of the brand-color wash at the top of the schedule canvas.
        static let canvasWashHeight: CGFloat = 260
    }

    /// Insets for capsule pills (LIVE / FT badges).
    enum Pill {
        static let horizontalPadding: CGFloat = 7
        static let verticalPadding: CGFloat = 3
        /// Gap between the dot and the label inside the LIVE badge.
        static let contentSpacing: CGFloat = 5
    }

    /// Tint strengths. Kept low so color reads as a hint, never a block of paint.
    enum Opacity {
        static let liveRowTint: Double = 0.10
        static let chipBorder: Double = 0.06
        static let iconHalo: Double = 0.12
        static let canvasWash: Double = 0.12
        /// Dimmest point of the LIVE dot pulse.
        static let pulseMin: Double = 0.4
    }

    /// Animation tuning.
    enum Motion {
        static let pulseDuration: Double = 0.8
        /// Smallest scale the LIVE dot shrinks to mid-pulse.
        static let pulseScale: CGFloat = 0.6
    }
}
