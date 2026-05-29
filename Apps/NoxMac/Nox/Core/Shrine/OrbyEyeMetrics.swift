import CoreGraphics

/// Shared Orby eye sizing (local UI only).
enum OrbyEyeMetrics {
  /// Global eye scale (+8% vs original 9.5pt baseline; was +5% in visual polish pass).
  static let sizeScale: CGFloat = 1.08

  static func scaled(_ value: CGFloat) -> CGFloat {
    value * sizeScale
  }
}
