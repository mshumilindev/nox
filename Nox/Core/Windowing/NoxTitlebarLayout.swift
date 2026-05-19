import CoreGraphics

/// Titlebar / shell chrome vertical rhythm.
enum NoxTitlebarLayout {
  static func chromeVerticalPadding(compact: Bool) -> CGFloat {
    compact ? NoxSpacing.md : NoxSpacing.lg
  }

  static func chromeMinHeight(compact: Bool) -> CGFloat {
    compact ? 52 : 64
  }
}
