import CoreGraphics
import Foundation

enum OrbyCosmicStarColor: Equatable {
  case lavenderWhite
  case paleBlue
  case paleRose

  /// Soft fill for tiny internal stars (not UI indicators).
  func components(intensity: CGFloat) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
    switch self {
    case .lavenderWhite:
      return (0.94, 0.92, 1.0)
    case .paleBlue:
      return (0.78, 0.90, 1.0)
    case .paleRose:
      return (1.0, 0.86, 0.90)
    }
  }
}

enum OrbyCosmicStarStyle: Equatable {
  case dot
  case glint
}

struct OrbyCosmicStar: Identifiable, Equatable {
  let id: Int
  /// Normalized position in unit disk (center 0.5, 0.5).
  let nx: CGFloat
  let ny: CGFloat
  let radius: CGFloat
  let baseOpacity: Double
  let twinkleAmplitude: Double
  let twinkleRadiansPerSecond: Double
  let phase: Double
  let color: OrbyCosmicStarColor
  let style: OrbyCosmicStarStyle
  /// Extra stars that only emerge as Orby falls asleep (faded in by sleep depth).
  let sleepBonus: Bool

  func position(in size: CGSize) -> CGPoint {
    CGPoint(x: nx * size.width, y: ny * size.height)
  }

  func opacity(at time: TimeInterval, config: OrbyCosmicMaterialConfig) -> Double {
    let amp = twinkleAmplitude * Double(config.twinkleIntensity)
    let wave = sin(time * twinkleRadiansPerSecond + phase) * amp
    let raw = baseOpacity + wave
    let dim = OrbyCosmicStarCatalog.faceSafeDimming(nx: nx, ny: ny, config: config)
    let sleepReveal = sleepBonus ? Double(config.sleepDepth) : 1
    let cap = 0.80 + 0.18 * Double(config.sleepDepth)
    return min(max(raw * Double(config.starOpacityMultiplier) * dim * sleepReveal, 0), cap)
  }
}

/// Deterministic internal starfield (stable per process; not persisted).
enum OrbyCosmicStarCatalog {
  private static let catalogSeed: UInt64 = 0x4E_4F_58_5F_4F_52_42_59

  static let shared: [OrbyCosmicStar] = make(
    count: OrbyCosmicMaterialConfig.default.starCount,
    seed: catalogSeed
  )

  static func make(count: Int, seed: UInt64) -> [OrbyCosmicStar] {
    var rng = SplitMix64(seed: seed)
    var stars: [OrbyCosmicStar] = []
    stars.reserveCapacity(count)

    let bandAngle = OrbyCosmicMaterialConfig.milkyWayAngleRadians
    let bandDir = (x: cos(bandAngle), y: sin(bandAngle))
    let bandPerp = (x: -bandDir.y, y: bandDir.x)

    var attempts = 0
    while stars.count < count, attempts < count * 40 {
      attempts += 1

      let nx: CGFloat
      let ny: CGFloat
      // ~58% of stars cluster along the Milky-Way ridge (dense dusty band);
      // the rest are scattered across the whole disk so the field still feels natural.
      if rng.nextUnit() < 0.62 {
        let along = (rng.nextUnit() - 0.5) * 0.92            // position along the band
        // Gaussian-ish perpendicular spread (sum of two uniforms), tight to the ridge.
        let spread = ((rng.nextUnit() + rng.nextUnit()) - 1.0) * 0.14
        nx = CGFloat(0.5 + (bandDir.x * along + bandPerp.x * spread))
        ny = CGFloat(0.5 + (bandDir.y * along + bandPerp.y * spread))
      } else {
        let u = rng.nextUnit()
        let v = rng.nextUnit()
        let r = sqrt(u)
        let theta = v * 2 * Double.pi
        nx = CGFloat(0.5 + r * cos(theta) * 0.46)
        ny = CGFloat(0.5 + r * sin(theta) * 0.46)
      }
      guard nx > 0.04, nx < 0.96, ny > 0.04, ny < 0.96 else { continue }
      // Keep everything inside the orb disk.
      let cx = Double(nx) - 0.5
      let cy = Double(ny) - 0.5
      guard (cx * cx + cy * cy) <= 0.46 * 0.46 else { continue }

      // The extra stars that only appear during sleep are the tiniest "dust"
      // grains, so a sleeping sky gains lots of fine pinpricks rather than blobs.
      let sleepBonus = stars.count >= 32

      // Skew small so the dense field reads as fine stardust, not "acne" dots.
      let sizeRoll = rng.nextUnit()
      let radius: CGFloat
      if sleepBonus {
        radius = CGFloat(0.35 + rng.nextUnit() * 0.35)
      } else if sizeRoll < 0.64 {
        radius = CGFloat(0.4 + rng.nextUnit() * 0.3)
      } else if sizeRoll < 0.90 {
        radius = CGFloat(0.7 + rng.nextUnit() * 0.3)
      } else if sizeRoll < 0.98 {
        radius = CGFloat(1.1 + rng.nextUnit() * 0.4)
      } else {
        radius = CGFloat(1.7 + rng.nextUnit() * 0.4)
      }

      let colorRoll = rng.nextUnit()
      let color: OrbyCosmicStarColor
      if colorRoll < 0.80 {
        color = .lavenderWhite
      } else if colorRoll < 0.93 {
        color = .paleBlue
      } else {
        color = .paleRose
      }

      let strongTwinkle = rng.nextUnit() < 0.38
      let baseOpacity = 0.16 + rng.nextUnit() * (strongTwinkle ? 0.38 : 0.28)
      let amplitude = strongTwinkle
        ? 0.08 + rng.nextUnit() * 0.10
        : 0.03 + rng.nextUnit() * 0.07
      let cycleSeconds = 2.5 + rng.nextUnit() * 5.5
      let twinkleRadiansPerSecond = (2 * Double.pi) / cycleSeconds
      let phase = rng.nextUnit() * 2 * Double.pi

      let isGlint = radius >= 1.35 && rng.nextUnit() < 0.35
      let style: OrbyCosmicStarStyle = isGlint ? .glint : .dot

      if color == .paleRose, radius > 1.25, baseOpacity > 0.42, faceSafeDimming(nx: nx, ny: ny, config: .default) < 0.75 {
        continue
      }

      stars.append(
        OrbyCosmicStar(
          id: stars.count,
          nx: nx,
          ny: ny,
          radius: radius,
          baseOpacity: baseOpacity,
          twinkleAmplitude: amplitude,
          twinkleRadiansPerSecond: twinkleRadiansPerSecond,
          phase: phase,
          color: color,
          style: style,
          sleepBonus: sleepBonus
        )
      )
    }

    return stars
  }

  /// Elliptical face-safe zone — dimmer stars behind eyes/mouth.
  static func faceSafeDimming(nx: CGFloat, ny: CGFloat, config: OrbyCosmicMaterialConfig) -> Double {
    let dx = (Double(nx) - 0.50) / 0.19
    let dy = (Double(ny) - 0.50) / 0.155
    let d2 = dx * dx + dy * dy
    if d2 >= 1 { return 1 }
    let inside = 1 - d2
    let dim = Double(config.faceSafeZoneDimming) * inside
    return max(0.30, 1 - dim)
  }
}

/// Fast deterministic PRNG for stable star layouts.
private struct SplitMix64 {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed &+ 0x9E37_79B9_7F4A_7C15
  }

  mutating func nextUnit() -> Double {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    z = z ^ (z >> 31)
    return Double(z % 10_000) / 10_000
  }
}

