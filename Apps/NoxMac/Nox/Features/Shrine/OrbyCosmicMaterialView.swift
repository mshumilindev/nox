import SwiftUI
import NoxDesignCore

/// Internal cosmic glass body: base, nebula, starfield, vignette, highlight (clipped to circle).
struct OrbyCosmicMaterialView: View {
  let diameter: CGFloat
  let presentation: OrbyMiniVisualPresentation

  private var config: OrbyCosmicMaterialConfig {
    OrbyCosmicMaterialConfig.resolved(for: presentation)
  }

  private var lightingContext: OrbyOrbLightingContext {
    OrbyOrbLightingContext(
      sleepDepth: config.sleepDepth,
      backgroundLuminance: presentation.backgroundLuminance
    )
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
    if presentation.materialSimplified {
      simplifiedBody
    } else {
      animatedBody
    }
  }

  private var simplifiedBody: some View {
    ZStack {
      baseFill
      innerVignette
    }
    .frame(width: diameter, height: diameter)
    .clipShape(Circle())
    .allowsHitTesting(false)
  }

  private var animatedBody: some View {
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
        if !presentation.ambientSkyMeteors.isEmpty {
          OrbyAmbientMeteorLayerView(diameter: diameter, meteors: presentation.ambientSkyMeteors)
            .offset(x: shift.width * 0.85, y: shift.height * 0.85)
        }
        innerVignette
          .opacity(Double(1 - blend))

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
        OrbyOrbLighting.bodyFill(
          tint: presentation.emotion.tint,
          context: lightingContext
        )
      )
      .animation(OrbyOrbLighting.sleepLightingAnimation, value: lightingContext.sleepDepth)
      .animation(OrbyOrbLighting.sleepLightingAnimation, value: lightingContext.backgroundLuminance)
  }

  private var innerVignette: some View {
    let depth = Double(config.sleepDepth)
    return ZStack {
      Circle()
        .fill(
          RadialGradient(
            colors: [
              Color(red: 0.44, green: 0.36, blue: 0.68).opacity(0.55 * (1 - depth * 0.55)),
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
            colors: [
              Color.clear,
              Color(red: 0.04, green: 0.02, blue: 0.12).opacity(0.20 + 0.28 * depth)
            ],
            center: UnitPoint(x: 0.52, y: 0.80),
            startRadius: diameter * 0.10,
            endRadius: diameter * 0.54
          )
        )
    }
    .animation(OrbyOrbLighting.sleepLightingAnimation, value: config.sleepDepth)
  }
}
