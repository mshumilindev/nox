import SwiftUI

/// Inputs for orb body + bezel lighting (kept in sync during awake ↔ sleep ↔ wake).
struct OrbyOrbLightingContext: Equatable {
  var sleepDepth: CGFloat
  var backgroundLuminance: Double

  /// 0 = bright wallpaper, 1 = dark wallpaper (smooth, not a hard cutoff).
  var bezelDarkInfluence: CGFloat {
    let lum = min(max(backgroundLuminance, 0), 1)
    return CGFloat(min(max((0.52 - lum) / 0.38, 0), 1))
  }

  /// 0 = full awake lighting (lit upper-left allowed); 1 = sleep / dark (darken-only bias).
  var nightInfluence: CGFloat {
    let d = min(max(sleepDepth, 0), 1)
    return min(1, d + bezelDarkInfluence * (1 - d))
  }
}

/// Shared highlight axis for the orb base fill (bezel uses legacy inline gradients in chrome).
enum OrbyOrbLighting {
  /// Soft diagonal body wash: top-leading light, bottom-trailing shadow.
  static let highlightArcFraction: Double = 0.5
  /// Smooth awake ↔ sleep lighting on body fill.
  static let sleepLightingAnimation: Animation = .easeInOut(duration: 0.72)

  static var linearHighlightStart: UnitPoint { .topLeading }
  static var linearHighlightEnd: UnitPoint { .bottomTrailing }

  /// Soft diagonal body wash — same axis as the legacy bezel (top-leading light, bottom-trailing shadow).
  static func bodyFill(tint: OrbyTintAppearance, context: OrbyOrbLightingContext) -> LinearGradient {
    let influence = Double(context.nightInfluence)
    let d = Double(min(max(context.sleepDepth, 0), 1))
    let base = nightShiftedMidPurple(tint: tint, sleepDepth: context.sleepDepth)

    let litBoost = 0.10 * (1 - influence)
    let lit = brighten(base, by: litBoost)
    let dim = darken(base, by: 0.12 + 0.05 * d + 0.04 * influence)

    let stops: [Gradient.Stop] = [
      .init(color: color(blend(lit, base, influence * 0.22)), location: 0),
      .init(color: color(blend(lit, base, 0.28 + influence * 0.48)), location: 0.30),
      .init(color: color(base), location: 0.50),
      .init(color: color(blend(base, dim, 0.38 + d * 0.14 + influence * 0.08)), location: 0.72),
      .init(color: color(dim), location: 1),
    ]

    return LinearGradient(
      gradient: Gradient(stops: stops),
      startPoint: linearHighlightStart,
      endPoint: linearHighlightEnd
    )
  }

  // MARK: - Color math

  private static func nightShiftedMidPurple(
    tint: OrbyTintAppearance,
    sleepDepth: CGFloat
  ) -> (r: Double, g: Double, b: Double) {
    let mid = (
      r: 0.22 + Double(tint.warmShift) * 0.06 - Double(tint.desaturation) * 0.05,
      g: 0.14 + Double(tint.warmShift) * 0.03 - Double(tint.desaturation) * 0.04,
      b: 0.42 - Double(tint.redShift) * 0.10 + Double(tint.cyanShift) * 0.08
    )
    let k = Double(min(max(sleepDepth, 0), 1)) * 0.92
    let night = (r: 0.035, g: 0.015, b: 0.10)
    return (
      r: mid.r + (night.r - mid.r) * k,
      g: mid.g + (night.g - mid.g) * k,
      b: mid.b + (night.b - mid.b) * k
    )
  }

  private static func brighten(_ rgb: (r: Double, g: Double, b: Double), by amount: Double) -> (r: Double, g: Double, b: Double) {
    (
      r: min(1, rgb.r + amount * 0.55),
      g: min(1, rgb.g + amount * 0.42),
      b: min(1, rgb.b + amount * 0.38)
    )
  }

  private static func darken(_ rgb: (r: Double, g: Double, b: Double), by amount: Double) -> (r: Double, g: Double, b: Double) {
    (
      r: max(0, rgb.r - amount * 0.62),
      g: max(0, rgb.g - amount * 0.68),
      b: max(0, rgb.b - amount * 0.45)
    )
  }

  private static func blend(
    _ a: (r: Double, g: Double, b: Double),
    _ b: (r: Double, g: Double, b: Double),
    _ t: Double
  ) -> (r: Double, g: Double, b: Double) {
    (
      r: a.r + (b.r - a.r) * t,
      g: a.g + (b.g - a.g) * t,
      b: a.b + (b.b - a.b) * t
    )
  }

  private static func color(_ rgb: (r: Double, g: Double, b: Double)) -> Color {
    Color(red: rgb.r, green: rgb.g, blue: rgb.b)
  }
}
