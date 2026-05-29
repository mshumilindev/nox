import CoreGraphics
import Foundation

/// Post-drag dizzy star orbit, centered on the painted orb inside the padded chrome canvas.
enum OrbyDizzyStarsGeometry {
  static let shadowPadding: CGFloat = OrbyOrbGeometry.chromePadding
  static let canvasSize: CGFloat = OrbyOrbGeometry.orbDiameter + shadowPadding * 2

  /// Orb center in the padded chrome canvas (orb is centered in chrome).
  static var orbCenter: CGPoint {
    CGPoint(
      x: canvasSize / 2,
      y: shadowPadding + OrbyOrbGeometry.orbRadius
    )
  }

  /// Orbit center above the orb face (negative Y = up in SwiftUI).
  static let orbitCenterYOffset: CGFloat = -38

  /// Horizontal orbit radius (+10% vs original 32 pt).
  static let orbitRadiusX: CGFloat = 35.2
  static let orbitRadiusY: CGFloat = 12.1

  static let starSizeFront: CGFloat = 10.45
  static let starSizeBack: CGFloat = 7.15
  static let starSizeMid: CGFloat = 8.8

  static let orbitPeriodSeconds: TimeInterval = OrbyMiniVisualTiming.dizzyStarOrbitPeriodSeconds
}
