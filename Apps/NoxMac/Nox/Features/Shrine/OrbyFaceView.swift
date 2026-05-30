import SwiftUI
import NoxDesignCore

/// Orby — the living circular face inside Mini Shrine Bubble.
struct OrbyFaceView: View {
  let presentation: OrbyMiniVisualPresentation

  @State private var ambientBlinkNarrow: Double = 0
  @State private var animatedCheekBlushStrength: Double = 0
  /// Monotonic token guaranteeing only the latest blink chain stays alive. Each
  /// (re)start bumps this; recursive continuations bail if they're stale. Without
  /// it, repeated `allowsAmbientBlink` toggles spawn overlapping asyncAfter chains
  /// that accumulate and make Orby appear to blink more and more often over time.
  @State private var blinkGeneration: Int = 0

  private var emotion: OrbyEmotionAppearance { presentation.emotion }

  private var combinedNarrowAmount: Double {
    min(1, max(presentation.eyelidClosure, ambientBlinkNarrow))
  }

  private var isHoverExcited: Bool {
    if case .hoverExcited = presentation.phase { return true }
    return false
  }

  private var cheekBlushStrength: Double {
    presentation.cheekBlushStrength
  }

  private var cheekBlushLayout: OrbyCheekBlushLayout {
    OrbyCheekBlushGeometry.layout(
      leftEye: emotion.leftEye,
      rightEye: emotion.rightEye,
      eyeSpacing: emotion.eyeSpacing
    )
  }

  private var gazeOffset: CGSize {
    CGSize(
      width: presentation.cursorEyeOffset.width + presentation.scriptedEyeOffset.width,
      height: presentation.cursorEyeOffset.height + presentation.scriptedEyeOffset.height
    )
  }

  var body: some View {
    OrbyOrbChrome(presentation: presentation) {
      faceContent
    }
    .onAppear {
      if presentation.allowsAmbientBlink { scheduleAmbientBlink() }
    }
    .onChange(of: presentation.allowsAmbientBlink) { _, allowed in
      if allowed { scheduleAmbientBlink() } else { ambientBlinkNarrow = 0 }
    }
    .onChange(of: presentation.isExcited) { _, excited in
      if excited { ambientBlinkNarrow = 0 }
    }
    .onAppear {
      animatedCheekBlushStrength = presentation.cheekBlushStrength
    }
    .onChange(of: presentation.cheekBlushStrength) { old, new in
      let appearing = new > old
      withAnimation(
        .easeInOut(duration: OrbyCheekBlushGeometry.fadeDuration(appearing: appearing))
      ) {
        animatedCheekBlushStrength = new
      }
    }
  }

  private var faceContent: some View {
    ZStack {
      Circle()
        .fill(Color.black.opacity(0.12))
        .frame(width: 42, height: 42)
        .blur(radius: 3)

      VStack(spacing: 6) {
        eyeRow
          .overlay(alignment: .top) {
            OrbyCheekBlushView(strength: animatedCheekBlushStrength, layout: cheekBlushLayout)
          }
          .animation(sleepWakeAnimation, value: presentation.phase)
          .animation(eyeNarrowAnimation, value: combinedNarrowAmount)
        mouth
      }
      // Day readability: against the bright blue sky the dark features can wash
      // out, so add a soft violet shadow that strengthens with the day blend.
      .shadow(
        color: Color(red: 0.20, green: 0.12, blue: 0.34)
          .opacity(0.55 * Double(presentation.dayNightBlend)),
        radius: 1.2,
        x: 0,
        y: 0.5
      )
      .overlay {
        OrbyIdleMicroOverlayLayer(overlay: presentation.idleMicroOverlay)
          .frame(width: OrbyOrbGeometry.orbDiameter, height: OrbyOrbGeometry.orbDiameter)
          .offset(y: -15)
      }
      .scaleEffect(presentation.idleMicroOverlay.puffScale)
      .offset(
        x: presentation.idleFaceNudge.width + presentation.idleMicroOverlay.faceJitter.width,
        y: presentation.idleFaceNudge.height + presentation.idleMicroOverlay.faceJitter.height
      )
      .offset(gazeOffset)
      .animation(cursorGazeAnimation, value: gazeOffset)
      .offset(presentation.dragFaceLagOffset)
      .animation(presentation.isDragging ? nil : .easeOut(duration: 0.14), value: presentation.dragFaceLagOffset)
      .offset(x: wakeHeadNudge.width, y: faceVerticalCenterOffset + wakeHeadNudge.height + (presentation.isExcited ? -1 : 0) - emotion.microBob * 0.5)
      .rotationEffect(.degrees(presentation.idleFaceTiltDegrees))
      .opacity(faceOpacity)
      .rotation3DEffect(
        .degrees(presentation.headTurnYDegrees),
        axis: (x: 0, y: 1, z: 0),
        perspective: 0.55
      )
      .rotation3DEffect(
        .degrees(presentation.headTurnXDegrees),
        axis: (x: 1, y: 0, z: 0),
        perspective: 0.55
      )
    }
  }

  /// Nudges the eyes+mouth block down so the face sits on the orb's equator
  /// by default (the stack otherwise rides slightly high).
  private let faceVerticalCenterOffset: CGFloat = 3

  private var cursorGazeAnimation: Animation? {
    isAwakeTracking ? nil : .easeInOut(duration: 0.22)
  }

  private var isAwakeTracking: Bool {
    presentation.eyeTrackingFactor > 0.85
      && !presentation.isDragging
      && !isPostDragDazed
  }

  private var isPostDragDazed: Bool {
    if case .postDragDazed = presentation.phase { return true }
    return false
  }

  private var stylizedEyeReveal: Double {
    max(presentation.idleMicroOverlay.animeEyeReveal, presentation.idleMicroOverlay.catEyeReveal)
  }

  private var eyeRow: some View {
    HStack(spacing: emotion.eyeSpacing) {
      eye(isLeft: true)
      eye(isLeft: false)
    }
    .overlay {
      let overlay = presentation.idleMicroOverlay
      if overlay.animeEyeReveal > 0.001 {
        OrbyStylizedEyeRow(
          mode: .anime,
          reveal: overlay.animeEyeReveal,
          leftSlotWidth: resolvedMetrics(isLeft: true, spec: emotion.leftEye).width + 1,
          rightSlotWidth: resolvedMetrics(isLeft: false, spec: emotion.rightEye).width + 1,
          spacing: emotion.eyeSpacing
        )
        .offset(y: -1) // sit ~1pt higher than normal eyes
      } else if overlay.catEyeReveal > 0.001 {
        OrbyStylizedEyeRow(
          mode: .cat,
          reveal: overlay.catEyeReveal,
          leftSlotWidth: resolvedMetrics(isLeft: true, spec: emotion.leftEye).width + 1,
          rightSlotWidth: resolvedMetrics(isLeft: false, spec: emotion.rightEye).width + 1,
          spacing: emotion.eyeSpacing
        )
      }
    }
  }

  private var wakeHeadNudge: CGSize {
    guard isWakeGlance else { return .zero }
    return CGSize(
      width: CGFloat(presentation.headTurnYDegrees) * 0.14,
      height: CGFloat(-presentation.headTurnXDegrees) * 0.08
    )
  }

  private var sleepWakeAnimation: Animation {
    .easeInOut(duration: OrbyMiniVisualTiming.sleepWakeUIAnimationSeconds)
  }

  private var eyeNarrowAnimation: Animation {
    if case .sleepyTransition = presentation.phase {
      return .easeInOut(duration: OrbyMiniVisualTiming.sleepyTransitionUIAnimationSeconds)
    }
    if isWakePhase {
      return .easeInOut(duration: 0.12)
    }
    return .linear(duration: OrbyMiniVisualTiming.ambientBlinkCloseSeconds)
  }

  private var isWakePhase: Bool {
    switch presentation.phase {
    case .wakingQuickBlink, .wakingYawn, .wakingDoubleBlink, .wakingSquint,
         .wakingGlanceRight, .wakingGlanceLeft:
      true
    default:
      false
    }
  }

  private var faceOpacity: Double {
    min(max(presentation.faceBrightness, 0.82), 1.12)
  }

  private var isAsleep: Bool {
    if case .asleep = presentation.phase { return true }
    return false
  }

  private var usesAsleepFaceLayout: Bool {
    isAsleep || isSleepTransition
  }

  private var sleepyFeatureDim: Double {
    if isAsleep || isPostDragDazed { return 0.68 }
    let depth = Double(mouthSleepDepth)
    return 0.68 + 0.32 * (1 - depth)
  }

  @ViewBuilder
  private func eye(isLeft: Bool) -> some View {
    let spec = isLeft ? emotion.leftEye : emotion.rightEye
    let metrics = resolvedMetrics(isLeft: isLeft, spec: spec)
    let asleepDim: Double = sleepyFeatureDim

    OrbyEyeView(
      width: metrics.width,
      baseHeight: metrics.height,
      narrowAmount: combinedNarrowAmount,
      horizontalShift: metrics.horizontalShift,
      verticalShift: metrics.verticalShift,
      rotationDegrees: spec.rotationDegrees,
      color: faceForeground,
      dimOpacity: (presentation.isExcited ? 1 : (emotion.eyesDimmed ? 0.55 : 1)) * asleepDim
        * (1 - stylizedEyeReveal)
    )
  }

  private var mouth: some View {
    OrbyMouthView(
      parameters: presentation.mouthParameters,
      color: mouthFillColor
    )
    .opacity(mouthOpacity)
    .animation(OrbyOrbLighting.sleepLightingAnimation, value: mouthSleepDepth)
    .animation(sleepWakeAnimation, value: presentation.phase)
  }

  private var mouthSleepDepth: CGFloat {
    OrbySleepDepth.depth(for: presentation.phase)
  }

  /// Matches asleep eye dim (0.68); ramps to full opacity as sleep depth clears (wake yawn).
  private var mouthOpacity: Double {
    sleepyFeatureDim
  }

  private var mouthFillColor: Color {
    presentation.isExcited ? excitedFaceForeground : faceForeground
  }

  private var faceForeground: Color {
    Color(red: 0.98, green: 0.99, blue: 1.0).opacity(
      presentation.resolvedMood == .disconnected ? 0.42 : 0.98
    )
  }

  private var excitedFaceForeground: Color {
    Color(red: 1.0, green: 1.0, blue: 1.0).opacity(0.98)
  }

  private struct EyeMetrics {
    var width: CGFloat
    var height: CGFloat
    var horizontalShift: CGFloat
    var verticalShift: CGFloat
  }

  private func resolvedMetrics(isLeft: Bool, spec: OrbyEyeAppearance) -> EyeMetrics {
    let scaled = scaleEye(spec)
    if usesAsleepFaceLayout {
      return EyeMetrics(
        width: OrbyEyeMetrics.scaled(9),
        height: OrbyEyeMetrics.scaled(9),
        horizontalShift: 0,
        verticalShift: 0
      )
    }
    if presentation.isExcited {
      return EyeMetrics(
        width: scaled.width,
        height: scaled.height + OrbyEyeMetrics.scaled(1.2),
        horizontalShift: spec.horizontalShift,
        verticalShift: spec.verticalShift
      )
    }
    if presentation.isDragging {
      return EyeMetrics(
        width: scaled.width,
        height: OrbyEyeMetrics.scaled(10.5),
        horizontalShift: spec.horizontalShift,
        verticalShift: -0.5
      )
    }
    return EyeMetrics(
      width: scaled.width,
      height: scaled.height,
      horizontalShift: spec.horizontalShift,
      verticalShift: spec.verticalShift
    )
  }

  private func scaleEye(_ spec: OrbyEyeAppearance) -> (width: CGFloat, height: CGFloat) {
    (OrbyEyeMetrics.scaled(spec.width), OrbyEyeMetrics.scaled(spec.height))
  }

  private var isWakeGlance: Bool {
    switch presentation.phase {
    case .wakingGlanceRight, .wakingGlanceLeft: true
    default: false
    }
  }

  private var isSleepTransition: Bool {
    if case .sleepyTransition = presentation.phase { return true }
    return false
  }

  /// Restarts the ambient blink loop, invalidating any previously running chain.
  private func scheduleAmbientBlink() {
    blinkGeneration &+= 1
    scheduleAmbientBlink(generation: blinkGeneration)
  }

  private func scheduleAmbientBlink(generation: Int) {
    guard generation == blinkGeneration else { return } // a newer chain superseded us
    let scale = max(emotion.blinkIntervalScale, 0.2)
    guard scale > 0, presentation.allowsAmbientBlink else { return }
    let range = presentation.ambientBlinkInterval
    let delay = Double.random(in: range.lowerBound...range.upperBound) * scale
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      guard generation == blinkGeneration else { return }
      guard presentation.allowsAmbientBlink, !presentation.isExcited else { return }
      let doubleBlink = Double.random(in: 0...1) < OrbyMiniVisualTiming.ambientDoubleBlinkProbability
      performAmbientBlink(double: doubleBlink) {
        scheduleAmbientBlink(generation: generation)
      }
    }
  }

  /// One shape-morph blink; optional second pulse after a short gap (realistic double blink).
  private func performAmbientBlink(double: Bool, completion: @escaping () -> Void) {
    runBlinkPulse {
      guard double else {
        completion()
        return
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + OrbyMiniVisualTiming.ambientBlinkDoubleGapSeconds) {
        self.runBlinkPulse(completion: completion)
      }
    }
  }

  private func runBlinkPulse(completion: @escaping () -> Void) {
    withAnimation(.easeIn(duration: OrbyMiniVisualTiming.ambientBlinkCloseSeconds)) {
      ambientBlinkNarrow = 1
    }
    let closed = OrbyMiniVisualTiming.ambientBlinkCloseSeconds + OrbyMiniVisualTiming.ambientBlinkHoldSeconds
    DispatchQueue.main.asyncAfter(deadline: .now() + closed) {
      withAnimation(.easeOut(duration: OrbyMiniVisualTiming.ambientBlinkOpenSeconds)) {
        ambientBlinkNarrow = 0
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + OrbyMiniVisualTiming.ambientBlinkOpenSeconds + 0.04) {
        completion()
      }
    }
  }
}

typealias ShrineMiniFaceView = OrbyFaceView
