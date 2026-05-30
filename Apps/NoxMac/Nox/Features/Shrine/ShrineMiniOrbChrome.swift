import SwiftUI

/// Circular Orby orb — depth via gradients/rim; shadow inside padding (no clipped drop shadow).
struct OrbyOrbChrome<Face: View>: View {
  let presentation: OrbyMiniVisualPresentation
  @ViewBuilder let face: () -> Face

  private let diameter: CGFloat = OrbyOrbGeometry.orbDiameter
  private var shadowPadding: CGFloat {
    presentation.materialSimplified ? 0 : OrbyOrbGeometry.chromePadding
  }

  @State private var breatheOut = false

  var body: some View {
    ZStack {
      groundShadow
      OrbyDazedHaloView(opacity: presentation.dazedHaloOpacity, layer: .back)
        .frame(width: diameter + shadowPadding * 2, height: diameter + shadowPadding * 2)
        .allowsHitTesting(false)
      if presentation.idleMicroOverlay.saturnRingOpacity > 0.001 {
        OrbySaturnRingView(
          overlay: presentation.idleMicroOverlay,
          layer: .back,
          orbDiameter: diameter
        )
        .frame(width: diameter, height: diameter)
      }
      deformedOrbAndFace
      if presentation.idleMicroOverlay.saturnRingOpacity > 0.001 {
        OrbySaturnRingView(
          overlay: presentation.idleMicroOverlay,
          layer: .front,
          orbDiameter: diameter
        )
        .frame(width: diameter, height: diameter)
      }
      OrbyDazedHaloView(opacity: presentation.dazedHaloOpacity, layer: .front)
        .frame(width: diameter + shadowPadding * 2, height: diameter + shadowPadding * 2)
        .allowsHitTesting(false)
      OrbyZzzView(
        opacity: presentation.zzzOpacity,
        backgroundLuminance: presentation.backgroundLuminance
      )
        .frame(width: diameter, height: diameter)
        .allowsHitTesting(false)
      OrbyParticleOverlayView(
        particle: presentation.emotion.overlayParticles,
        opacity: particleOpacity,
        backgroundLuminance: presentation.backgroundLuminance
      )
      .frame(width: diameter + shadowPadding * 2, height: diameter + shadowPadding * 2)
      .allowsHitTesting(false)

      if presentation.idleMicroOverlay.cometOpacity > 0.001 {
        OrbyCometView(
          opacity: presentation.idleMicroOverlay.cometOpacity,
          progress: presentation.idleMicroOverlay.cometProgress,
          boundsSide: diameter + shadowPadding * 2
        )
        .frame(width: diameter + shadowPadding * 2, height: diameter + shadowPadding * 2)
        .allowsHitTesting(false)
      }
    }
    .padding(shadowPadding)
    .frame(width: diameter + shadowPadding * 2, height: diameter + shadowPadding * 2)
    .scaleEffect(orbScale)
    .onAppear { startBreathingIfNeeded() }
    .onChange(of: isBreathingPhase) { _, breathing in
      if breathing { startBreathingIfNeeded() } else { breatheOut = false }
    }
    .accessibilityHidden(true)
  }

  /// Soft oval under the orb, fully inside padded bounds — never clipped by panel.
  private var groundShadow: some View {
    Ellipse()
      .fill(Color.black.opacity(presentation.materialSimplified ? 0 : 0.28))
      .frame(width: diameter * 0.62, height: diameter * 0.14)
      .blur(radius: 5)
      .offset(y: diameter * 0.36)
  }

  private var particleOpacity: Double {
    if case .postDragDazed = presentation.phase { return 0 }
    if presentation.isDragging { return 0 }
    return 1
  }

  private var deformedOrbAndFace: some View {
    let d = presentation.dragDeformation
    let faceStrength = presentation.dragFaceDeformationStrength
    let faceStretch = 1 + (d.stretch - 1) * faceStrength
    let faceCompression = 1 + (d.compression - 1) * faceStrength

    return ZStack {
      orbShell
        .modifier(
          OrbyDragDeformationModifier(
            stretch: d.stretch,
            compression: d.compression,
            angleRadians: d.angleRadians
          )
        )
      face()
        .frame(width: diameter, height: diameter)
        .modifier(
          OrbyDragDeformationModifier(
            stretch: faceStretch,
            compression: faceCompression,
            angleRadians: d.angleRadians
          )
        )
        .allowsHitTesting(false)
    }
    .frame(width: diameter, height: diameter)
  }

  private var lightingContext: OrbyOrbLightingContext {
    OrbyOrbLightingContext(
      sleepDepth: OrbySleepDepth.depth(for: presentation.phase),
      backgroundLuminance: presentation.backgroundLuminance
    )
  }

  private var orbShell: some View {
    let lighting = lightingContext
    return ZStack {
      OrbyCosmicMaterialView(diameter: diameter, presentation: presentation)

      tintOverlay

      stylizedSkyOverlays

      Circle()
        .strokeBorder(
          LinearGradient(
            colors: [
              Color.white.opacity(0.42),
              Color.white.opacity(0.12),
              Color.black.opacity(0.45)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1.25
        )

      Circle()
        .inset(by: 2)
        .stroke(Color.white.opacity(0.10), lineWidth: 0.5)

      adaptiveBezel
      idleRimGlint
    }
    .frame(width: diameter, height: diameter)
    .animation(OrbyOrbLighting.sleepLightingAnimation, value: lighting.sleepDepth)
    .animation(OrbyOrbLighting.sleepLightingAnimation, value: lighting.backgroundLuminance)
  }

  private var idleRimGlint: some View {
    let g = presentation.idleMicroOverlay
    return Circle()
      .trim(from: max(0, g.rimGlintProgress - 0.18), to: min(1, g.rimGlintProgress + 0.08))
      .stroke(
        Color.white.opacity(0.35 * g.rimGlintOpacity),
        style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
      )
      .rotationEffect(.degrees(-128))
      .padding(3)
      .opacity(g.rimGlintOpacity)
      .allowsHitTesting(false)
  }

  /// In-orb overlays for stylized beats (noir grading + bands, black hole). Clipped to circle,
  /// rendered above the sky material but below the bezel/face.
  @ViewBuilder
  private var stylizedSkyOverlays: some View {
    let o = presentation.idleMicroOverlay
    if o.noirReveal > 0.001 {
      OrbyNoirGradingView(
        reveal: o.noirReveal,
        bandPhase: o.noirBandPhase,
        clueOpacity: o.noirClueOpacity,
        diameter: diameter
      )
    }
    if o.blackHoleStrength > 0.001 {
      OrbyBlackHoleView(
        strength: o.blackHoleStrength,
        side: o.blackHoleSide,
        starProgress: o.blackHoleStarProgress,
        diameter: diameter
      )
    }
  }

  private var tintOverlay: some View {
    let t = presentation.emotion.tint
    return Circle()
      .fill(
        RadialGradient(
          colors: [
            Color.red.opacity(t.redShift * 0.35),
            Color.orange.opacity(t.amberShift * 0.28),
            Color.cyan.opacity(t.cyanShift * 0.2),
            Color.clear
          ],
          center: .center,
          startRadius: 4,
          endRadius: diameter * 0.5
        )
      )
      .opacity(t.brightness > 1 ? 0.9 : 0.75)
  }

  private var adaptiveBezel: some View {
    let dark = presentation.bezelOnDarkBackground
    let b = presentation.emotion.bezel
    let prom = b.prominenceScale * (dark ? 1.08 : 0.95)
    let topWhite = (dark ? 0.70 : 0.46) * prom
    let softViolet = (dark ? 0.34 : 0.16) * prom
    let lowerShadow = (dark ? 0.42 : 0.24) * prom
    let innerLight = (dark ? 0.22 : 0.12) * prom
    let outerSeparation = (dark ? 0.24 : 0.10) * prom

    return ZStack {
      Circle()
        .stroke(Color.black.opacity(outerSeparation), lineWidth: dark ? 1.8 : 1.1)
      Circle()
        .strokeBorder(
          AngularGradient(
            colors: [
              Color.white.opacity(topWhite),
              Color.white.opacity(topWhite * 0.70),
              Color(red: 0.74, green: 0.64, blue: 1.0).opacity(softViolet),
              Color.black.opacity(lowerShadow),
              Color.black.opacity(lowerShadow * 0.70),
              Color(red: 0.76, green: 0.68, blue: 1.0).opacity(softViolet),
              Color.white.opacity(topWhite)
            ],
            center: .center,
            angle: .degrees(-118)
          ),
          lineWidth: dark ? 2.3 : 1.7
        )
      Circle()
        .inset(by: 1.8)
        .strokeBorder(
          AngularGradient(
            colors: [
              Color.white.opacity(innerLight),
              Color.white.opacity(innerLight * 0.55),
              Color.clear,
              Color.black.opacity(dark ? 0.22 : 0.10),
              Color.clear,
              Color.white.opacity(innerLight)
            ],
            center: .center,
            angle: .degrees(-112)
          ),
          lineWidth: 0.9
        )
      Circle()
        .inset(by: 3.1)
        .strokeBorder(
          LinearGradient(
            colors: [
              Color.white.opacity(dark ? 0.18 : 0.10),
              Color.clear,
              Color.black.opacity(dark ? 0.18 : 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 0.65
        )
      Circle()
        .stroke(Color.red.opacity(b.rimRed * 0.9), lineWidth: 1.1)
      Circle()
        .stroke(Color.orange.opacity(b.rimAmber * 0.85), lineWidth: 1.0)
    }
  }

  private var isBreathingPhase: Bool {
    switch presentation.phase {
    case .sleepyTransition, .asleep: true
    default: false
    }
  }

  private var orbScale: CGFloat {
    let base = presentation.orbScale
    // Asleep / waking: drive the swell directly from the synced breath value so
    // the orb grows on inhale and shrinks on exhale together with the mouth, and
    // eases back to its resting size as the wake yawn finishes (depth → 0).
    let depth = OrbySleepDepth.depth(for: presentation.phase)
    if depth > 0 {
      let amp: CGFloat = 0.022 * depth
      let signed = CGFloat(presentation.sleepBreath) * 2 - 1 // -1 … 1
      return base * (1 + amp * signed)
    }
    guard isBreathingPhase else { return base }
    let amp: CGFloat = switch presentation.phase {
    case .sleepyTransition(let progress): 0.002 + CGFloat(progress) * 0.006
    default: 0.004
    }
    return base * (breatheOut ? 1 + amp : 1 - amp)
  }

  private func startBreathingIfNeeded() {
    guard isBreathingPhase else { return }
    let duration: Double = presentation.phase == .asleep ? 4.2 : 4.8 // breathing
    withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
      breatheOut = true
    }
  }
}

typealias ShrineMiniOrbChrome<Face: View> = OrbyOrbChrome<Face>
