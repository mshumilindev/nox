import SwiftUI
import NoxDesignCore

/// Internal cosmic glass body: base, nebula, starfield, vignette, highlight (clipped to circle).
struct OrbyCosmicMaterialView: View {
  let diameter: CGFloat
  let presentation: OrbyMiniVisualPresentation

  private var config: OrbyCosmicMaterialConfig {
    OrbyCosmicMaterialConfig.resolved(for: presentation)
  }

  /// Cosmic layers shift opposite to the head tilt to read as a deep interior (parallax).
  /// Far layers (nebula / Milky-Way) move least; the nearer starfield moves most.
  private var parallax: CGSize {
    let s = config.parallaxStrength
    let tiltX = CGFloat(presentation.headTurnYDegrees) // left / right turn
    let tiltY = CGFloat(presentation.headTurnXDegrees) // up / down nod
    return CGSize(width: -tiltX * 0.42 * s, height: tiltY * 0.42 * s)
  }

  var body: some View {
    let shift = parallax
    return TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
      let drift = timeline.date.timeIntervalSinceReferenceDate / 48
      let blend = config.dayNightBlend
      ZStack {
        baseFill
        OrbyNebulaView(diameter: diameter, config: config, driftPhase: drift)
          .offset(x: shift.width * 0.55, y: shift.height * 0.55)
          .opacity(Double(config.nebulaVisibility))
        OrbyStarfieldView(diameter: diameter, config: config)
          .offset(x: shift.width, y: shift.height)
          .opacity(Double(config.starVisibility))
        innerVignette
          .opacity(Double(1 - blend))

        // Day sky crossfades in over the cosmos, sun glow rises in the back half.
        if config.daySkyVisibility > 0.001 {
          OrbyDaySkyView(blend: blend, diameter: diameter)
            .opacity(Double(config.daySkyVisibility))
        }
        if config.sunVisibility > 0.001 {
          OrbySunGlowView(diameter: diameter)
            .offset(x: shift.width * 0.4, y: shift.height * 0.4)
            .opacity(Double(config.sunVisibility))
        }
      }
    }
    .frame(width: diameter, height: diameter)
    .clipShape(Circle())
    .allowsHitTesting(false)
    .animation(.easeOut(duration: 0.18), value: shift)
  }

  private var baseFill: some View {
    Circle()
      .fill(
        LinearGradient(
          colors: baseGradientColors,
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
  }

  private var innerVignette: some View {
    ZStack {
      Circle()
        .fill(
          RadialGradient(
            colors: [
              Color(red: 0.44, green: 0.36, blue: 0.68).opacity(0.55),
              Color.clear
            ],
            center: UnitPoint(x: 0.30, y: 0.26),
            startRadius: 2,
            endRadius: diameter * 0.52
          )
        )
      Circle()
        .fill(
          RadialGradient(
            colors: [Color.clear, Color(red: 0.04, green: 0.02, blue: 0.12).opacity(0.48)],
            center: UnitPoint(x: 0.52, y: 0.80),
            startRadius: diameter * 0.10,
            endRadius: diameter * 0.54
          )
        )
    }
  }


  private var baseGradientColors: [Color] {
    let t = presentation.emotion.tint
    let baseTop = (
      r: 0.40 + Double(t.warmShift) * 0.14 - Double(t.desaturation) * 0.08,
      g: 0.30 + Double(t.warmShift) * 0.07 - Double(t.desaturation) * 0.06,
      b: 0.62 - Double(t.redShift) * 0.18 + Double(t.cyanShift) * 0.12
    )
    // NoxAtmosphericModalPalette.violetMist == Color(hex: 0x2A2450)
    let violetMist = (r: 0x2A / 255.0, g: 0x24 / 255.0, b: 0x50 / 255.0)
    let baseMid = (r: 0.22, g: 0.14, b: 0.42)
    let baseBottom = (
      r: 0.10 + Double(t.redShift) * 0.22 + Double(t.amberShift) * 0.08,
      g: 0.07 - Double(t.redShift) * 0.04,
      b: 0.22 - Double(t.coolShift) * 0.05
    )
    let stops = [baseTop, violetMist, baseMid, baseBottom]
    return stops.map { OrbyCosmicMaterialView.nightShifted($0, depth: config.sleepDepth) }
  }

  /// Eases each base stop toward a deep "night purple" as Orby falls asleep,
  /// returning to the regular violet by the time the wake yawn finishes.
  private static func nightShifted(_ rgb: (r: Double, g: Double, b: Double), depth: CGFloat) -> Color {
    let k = Double(min(max(depth, 0), 1)) * 0.92
    // Very deep night-purple target (near-black indigo).
    let night = (r: 0.035, g: 0.015, b: 0.10)
    return Color(
      red: rgb.r + (night.r - rgb.r) * k,
      green: rgb.g + (night.g - rgb.g) * k,
      blue: rgb.b + (night.b - rgb.b) * k
    )
  }
}
