import CoreGraphics

/// Titlebar / shell chrome vertical rhythm.
enum NoxTitlebarLayout {
    /// Top band left clear for macOS traffic lights (close / minimize / zoom).
    static let trafficLightBandHeight: CGFloat = 28

    static func chromeVerticalPadding(compact: Bool) -> CGFloat {
        compact ? NoxSpacing.md : NoxSpacing.lg
    }

    static func chromeMinHeight(compact: Bool) -> CGFloat {
        compact ? 52 : 64
    }
}
