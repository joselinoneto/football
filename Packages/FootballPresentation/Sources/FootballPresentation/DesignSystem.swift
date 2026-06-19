import CoreGraphics

/// App-wide design tokens. Every spacing, size, radius, opacity, and motion
/// value the UI uses lives here so the look stays consistent and can be tuned
/// from one place. Views should reference these instead of hard-coding numbers.
///
/// Brand colors live per-app in `Theme.swift` (they depend on platform UI
/// frameworks, so they cannot be shared here).
public enum Design {

    /// Spacing and padding on a 2-pt grid. Ordered small → large; the four
    /// `section*` steps are reserved for screen-level rhythm.
    public enum Spacing {
        public static let xxSmall: CGFloat = 2
        public static let xSmall: CGFloat = 4
        public static let small: CGFloat = 6
        public static let medium: CGFloat = 8
        public static let large: CGFloat = 10
        public static let xLarge: CGFloat = 12
        public static let xxLarge: CGFloat = 14
        public static let xxxLarge: CGFloat = 16
        public static let section: CGFloat = 24
        public static let sectionLarge: CGFloat = 28
        public static let screenBottom: CGFloat = 32
    }

    /// Corner radii for filled containers.
    public enum Radius {
        public static let card: CGFloat = 20
    }

    /// Fixed element dimensions that can't come from Dynamic Type.
    public enum Size {
        /// Width of the flag column, so both team lines align.
        public static let flagColumn: CGFloat = 30
        /// Width of the minute column in the goal timeline, so scorers align.
        public static let goalMinuteColumn: CGFloat = 48
        /// Pulsing dot inside the LIVE badge.
        public static let liveDot: CGFloat = 6
        /// Accent dot next to the "Today" section header.
        public static let todayDot: CGFloat = 7
        /// About-screen icon glyph and the halo behind it.
        public static let aboutGlyph: CGFloat = 78
        public static let aboutHalo: CGFloat = 136
        /// Height of the brand-color wash at the top of the schedule canvas.
        public static let canvasWashHeight: CGFloat = 260
    }

    /// Insets for capsule pills (LIVE / FT badges).
    public enum Pill {
        public static let horizontalPadding: CGFloat = 7
        public static let verticalPadding: CGFloat = 3
        /// Gap between the dot and the label inside the LIVE badge.
        public static let contentSpacing: CGFloat = 5
    }

    /// Tint strengths. Kept low so color reads as a hint, never a block of paint.
    public enum Opacity {
        public static let liveRowTint: Double = 0.10
        public static let chipBorder: Double = 0.06
        public static let iconHalo: Double = 0.12
        public static let canvasWash: Double = 0.12
        /// Dimmest point of the LIVE dot pulse.
        public static let pulseMin: Double = 0.4
    }

    /// Animation tuning.
    public enum Motion {
        public static let pulseDuration: Double = 0.8
        /// Smallest scale the LIVE dot shrinks to mid-pulse.
        public static let pulseScale: CGFloat = 0.6
    }
}
