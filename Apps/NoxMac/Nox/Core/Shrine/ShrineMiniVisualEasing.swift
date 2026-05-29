import Foundation

enum OrbyMiniVisualEasing {
  /// Smooth 0…1 ease (no overshoot).
  static func smoothstep(_ t: Double) -> Double {
    let x = min(max(t, 0), 1)
    return x * x * (3 - 2 * x)
  }

  /// Extra-soft for eyelids / mood cross-fades.
  static func gentler(_ t: Double) -> Double {
    let x = smoothstep(t)
    return x * x * (3 - 2 * x)
  }

  static func easeOutCubic(_ t: Double) -> Double {
    let x = min(max(t, 0), 1)
    let inv = 1 - x
    return 1 - inv * inv * inv
  }

  static func exponentialEaseOut(_ t: Double) -> Double {
    let x = min(max(t, 0), 1)
    if x >= 1 { return 1 }
    return 1 - pow(2, -8 * x)
  }

  /// Slow eyelid close while falling asleep (zero slope at start and end).
  static func sleepyEyelidClose(_ t: Double) -> Double {
    let x = min(max(t, 0), 1)
    return x * x * x * (x * (x * 6 - 15) + 10)
  }
}

typealias ShrineMiniVisualEasing = OrbyMiniVisualEasing
