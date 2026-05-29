import CoreGraphics
import Foundation

/// Tunable intensity for Orby’s internal cosmic body material.
struct OrbyCosmicMaterialConfig: Equatable {
  var starCount: Int = 64
  var starOpacityMultiplier: CGFloat = 1.0
  var twinkleIntensity: CGFloat = 1.0
  var nebulaOpacity: CGFloat = 1.0
  var coloredStarIntensity: CGFloat = 1.0
  var faceSafeZoneDimming: CGFloat = 0.55
  var nebulaDriftEnabled: Bool = true
  /// Milky-Way band intensity (0 disables the band entirely).
  var milkyWayIntensity: CGFloat = 1.0
  /// Parallax depth — how far cosmic layers shift in response to Orby's head tilt.
  var parallaxStrength: CGFloat = 1.0
  /// 0 = awake, 1 = deeply asleep. Drives the deeper night-purple base and the
  /// denser / brighter / larger starfield while Orby sleeps.
  var sleepDepth: CGFloat = 0
  /// 0 = night, 1 = day. Stars / nebula / vignette fade out as this rises and the
  /// day sky + sun glow fade in (handled in OrbyCosmicMaterialView).
  var dayNightBlend: CGFloat = 0

  /// Visibility multipliers derived from `dayNightBlend`.
  var starVisibility: CGFloat { CGFloat(pow(1 - Double(min(max(dayNightBlend, 0), 1)), 1.5)) }
  var nebulaVisibility: CGFloat { CGFloat(pow(1 - Double(min(max(dayNightBlend, 0), 1)), 1.2)) }
  /// Sun rises only in the back half of the blend so it doesn't bloom at dusk/dawn.
  var sunVisibility: CGFloat {
    let b = min(max(dayNightBlend, 0), 1)
    let t = min(max((b - 0.25) / 0.75, 0), 1)
    return t * t * (3 - 2 * t)
  }
  var daySkyVisibility: CGFloat { min(max(dayNightBlend, 0), 1) }

  /// Shared axis (radians) for the Milky-Way band and the star clustering along it,
  /// so the dust lane and the dense star ridge always line up. Stretched diagonally
  /// from the bottom-right corner up to the top-left corner.
  static let milkyWayAngleRadians: Double = 0.785 // ~ +45° (bottom-right → top-left)

  static let `default` = OrbyCosmicMaterialConfig()

  /// Phase / mood adjustments on top of defaults (rich baseline; dial down via multipliers).
  static func resolved(for presentation: OrbyMiniVisualPresentation) -> OrbyCosmicMaterialConfig {
    var config = OrbyCosmicMaterialConfig.default
    let tint = presentation.emotion.tint

    // Sleep deepens the cosmos: more, brighter, larger, livelier stars and a
    // richer nebula as Orby drifts off, returning to baseline by the yawn's end.
    let depth = OrbySleepDepth.depth(for: presentation.phase)
    config.sleepDepth = depth
    config.starOpacityMultiplier *= (1 + 0.65 * depth)
    config.twinkleIntensity *= (1 + 0.95 * depth)
    config.nebulaOpacity *= (1 + 0.30 * depth)
    config.milkyWayIntensity *= (1 + 0.55 * depth)

    // Daytime fades the cosmos out. Multiply the night elements by their
    // visibility so stars, nebula, and the Milky-Way band recede into the
    // clear blue sky (the day sky + sun are layered separately in the view).
    config.dayNightBlend = presentation.dayNightBlend
    config.starOpacityMultiplier *= config.starVisibility
    config.coloredStarIntensity *= config.starVisibility
    config.nebulaOpacity *= config.nebulaVisibility
    config.milkyWayIntensity *= config.nebulaVisibility

    switch presentation.phase {
    case .hoverExcited:
      config.starOpacityMultiplier *= 1.08
      config.twinkleIntensity *= 1.06
      config.nebulaOpacity *= 1.05
    case .launchGreeting:
      config.starOpacityMultiplier *= 1.06
      config.nebulaOpacity *= 1.04
    default:
      break
    }

    if tint.brightness < 0.94 {
      config.starOpacityMultiplier *= 0.88
      config.twinkleIntensity *= 0.82
    }
    if tint.desaturation > 0.08 {
      config.nebulaOpacity *= 0.92
    }
    if presentation.isDragging {
      config.twinkleIntensity *= 0.88
    }

    return config
  }
}
