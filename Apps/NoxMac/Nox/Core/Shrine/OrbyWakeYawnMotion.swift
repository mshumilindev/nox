import Foundation

/// Wake yawn head arc and eyelids (mouth curve lives in `OrbyWakeMouthParameters`).
enum OrbyWakeYawnMotion {
  private static let maxY = OrbyMiniVisualTiming.maxHeadTurnYDegrees
  private static let maxX = OrbyMiniVisualTiming.maxHeadTurnXDegrees

  /// Thin sleepy lines for the whole yawn — never wide-open eyes with a huge mouth.
  static func eyelidClosure(progress: Double) -> Double {
    let t = min(max(progress, 0), 1)
    if t < 0.10 {
      return 0.96
    }
    if t < 0.88 {
      return 0.93
    }
    let p = OrbyMiniVisualEasing.smoothstep((t - 0.88) / 0.12)
    return 0.93 - p * 0.12
  }

  /// Smooth sleepy head arc: up/back during max-open hold, then quick settle.
  static func headTurn(progress: Double) -> (x: Double, y: Double) {
    let t = min(max(progress, 0), 1)
    let start = (x: -maxX * 0.10, y: -maxY * 0.18)
    let lift = (x: -maxX * 0.88, y: -maxY * 0.10)
    let back = (x: -maxX * 1.28, y: maxY * 0.62)
    let settle = (x: -maxX * 0.24, y: maxY * 0.20)
    let center = (x: 0.0, y: 0.0)

    if t < 0.50 {
      let p = OrbyMiniVisualEasing.exponentialEaseOut(t / 0.50)
      return lerp(start, lift, p)
    }
    if t < 0.89 {
      let p = (t - 0.50) / 0.39
      let arc = sin(p * .pi)
      let base = lerp(lift, back, p)
      return (x: base.x - maxX * 0.10 * arc, y: base.y + maxY * 0.10 * arc)
    }
    if t < 0.96 {
      let p = OrbyMiniVisualEasing.smoothstep((t - 0.89) / 0.07)
      return lerp(back, settle, p)
    }
    let p = OrbyMiniVisualEasing.smoothstep((t - 0.96) / 0.04)
    return lerp(settle, center, p)
  }

  private static func lerp(
    _ a: (x: Double, y: Double),
    _ b: (x: Double, y: Double),
    _ t: Double
  ) -> (x: Double, y: Double) {
    (
      x: a.x + (b.x - a.x) * t,
      y: a.y + (b.y - a.y) * t
    )
  }
}
