import AppKit
import Foundation
import Observation

/// Orby visual state: cursor follow, sleep/wake, drag lag, post-drag dazed. Never persisted.
@MainActor
@Observable
final class OrbyMiniVisualController {
  private(set) var cursorEyeOffset: CGSize = .zero
  private(set) var dragFaceLagOffset: CGSize = .zero
  private(set) var dragPhysicsRenderTick: UInt = 0
  private let dragPhysics = OrbyDragPhysicsSimulator()
  private(set) var headTurnXDegrees: Double = 0
  private(set) var headTurnYDegrees: Double = 0
  var isHovering = false
  var isDragging = false
  var isContextMenuOpen = false

  /// Test / diagnostics seam for post-drag dazed without building full presentation.
  var isPostDragDazedActive: Bool {
    if case .postDragDazed = phase { return true }
    return false
  }

  var onPostDragDazedFinished: (() -> Void)?

  var isLaunchGreetingActive: Bool {
    if case .launchGreeting = phase { return true }
    return false
  }

  private(set) var surfaceForm: OrbySurfaceForm = .bubble
  private(set) var notchPreviewBlend: CGFloat = 0
  private(set) var notchPullTension: CGFloat = 0
  private(set) var notchPullVisualOffset: CGSize = .zero
  private(set) var notchUndockTrembleOffset: CGSize = .zero

  private var phase: OrbyMiniVisualPhase = .awake
  private var postDragDazedStartedAt: Date?
  private var dragStartedAt: Date?
  private var wakeSequenceStartedAt: Date?
  private var wakePhaseGapEndsAt: Date?
  private var wakeHandoffAfterGap: WakeRitualHandoff?

  private enum WakeRitualHandoff {
    case nextPhase(OrbyMiniVisualPhase)
    case finish
  }
  private var wakeMouthCrossfade: Double = 1
  private var wakeMouthCrossfadeFrom: OrbyMouthParameters = OrbyWakeMouthParameters.closedSlit
  private var wakeMouthCrossfadeTo: OrbyMouthParameters = OrbyEmotionAppearance.neutralDefault.mouth
  private var wakeMouthCrossfadeStartedAt: Date?
  private var mouthSettleTrackedKind: OrbyMouthPhaseKind?
  private var lastRenderedMouth: OrbyMouthParameters = OrbyEmotionAppearance.neutralDefault.mouth
  private var launchGreetingStartedAt: Date?
  private var pendingHoverExcitedAfterGreeting = false
  private var baselineBlinkResumeAt: Date?
  private var lastMeaningfulMovementAt = Date()
  private var lastCursorMovementAt = Date()
  private var lastSampledScreenPoint: NSPoint?
  private var sleepyTransitionEnteredAt: Date?
  /// When Orby last fully entered `.asleep`. Drives the 2s flat-line hold before breathing.
  private var asleepEnteredAt: Date?

  private var targetEyeOffset: CGSize = .zero
  private var targetHeadTurnX: Double = 0
  private var targetHeadTurnY: Double = 0

  private weak var panel: NSPanel?
  private var timer: Timer?
  private var contextMenuMonitor: Any?
  private var smoothedEyelidClosure: Double = 0
  private var gazeHoldEyeOffset: CGSize?
  private(set) var bezelOnDarkBackground = false
  private(set) var backgroundLuminance: Double = 0.5
  /// Bumped while a microbehavior runs so SwiftUI re-renders progress (scheduler is not @Observable).
  private(set) var idleMicroRenderTick: UInt = 0
  /// Bumped while notch undock tremble / resistance is active.
  private(set) var notchVisualRenderTick: UInt = 0
  /// Bumped every frame while a passive sky event is visible.
  private(set) var ambientSkyRenderTick: UInt = 0
  /// Bumped every frame while Orby sleeps so the breathing (mouth + orb) re-renders smoothly.
  private(set) var sleepBreathRenderTick: UInt = 0
  /// Mouth shape captured at the moment Orby starts waking, so the first wake
  /// motion morphs out of whatever the breathing mouth happened to be.
  private var wakeEntryMouth: OrbyMouthParameters?
  private var wakeEntryStartedAt: Date?
  private let idleMicroScheduler = OrbyIdleMicrobehaviorScheduler()
  private let ambientSkyScheduler = OrbyAmbientSkyEventScheduler()
  private var lastResolvedMood: OrbyMood = .neutral
  private var tickCounter: UInt = 0

  func attach(panel: NSPanel) {
    self.panel = panel
  }

  /// Active tick rate: 60 fps for animations, 30 fps when idle.
  private static let activeInterval: TimeInterval = 1.0 / 60.0
  private static let idleInterval: TimeInterval = 1.0 / 30.0
  private var currentTimerInterval: TimeInterval = 1.0 / 60.0

  func start() {
    guard timer == nil else { return }
    lastMeaningfulMovementAt = Date()
    phase = .awake
    installTimer(interval: Self.activeInterval)
    installContextMenuMonitor()
    tick()
  }

  private func installTimer(interval: TimeInterval) {
    timer?.invalidate()
    currentTimerInterval = interval
    let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.tick()
      }
    }
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  /// Returns true when Orby needs high-frequency updates.
  private func needsActiveTickRate() -> Bool {
    if isDragging { return true }
    if dragPhysics.needsFrameUpdates { return true }
    if notchPullTension > 0 { return true }
    if isLaunchGreetingPhase { return true }
    if isWakePhase { return true }
    if isPostDragDazedPhase { return true }
    if case .sleepyTransition = phase { return true }
    if case .asleep = phase { return true }
    if idleMicroScheduler.active != nil { return true }
    // Hovering and awake/asleep are near-static — 10 fps is enough.
    return false
  }

  func stop() {
    timer?.invalidate()
    timer = nil
    removeContextMenuMonitor()
    resetTransientState()
  }

  func noteShow(playLaunchGreeting: Bool = false) {
    lastMeaningfulMovementAt = Date()
    lastCursorMovementAt = Date()
    sleepyTransitionEnteredAt = nil
    wakeSequenceStartedAt = nil
    pendingHoverExcitedAfterGreeting = false
    let shouldGreet = playLaunchGreeting && shouldPlayLaunchGreeting()
    if shouldGreet {
      idleMicroScheduler.noteShow()
      ambientSkyScheduler.noteShow()
      startLaunchGreeting()
    } else {
      phase = .awake
      idleMicroScheduler.noteManualShowcase()
      ambientSkyScheduler.noteShow()
    }
  }

  func setSurfaceForm(_ form: OrbySurfaceForm) {
    surfaceForm = form
    if form == .notch {
      cancelLaunchGreeting()
      idleMicroScheduler.cancelActiveForInteraction(now: Date(), mood: lastResolvedMood)
    }
    if OrbySurfaceFormBehavior.allowsIdleMicrobehaviors(form), !isDragging, !isContextMenuOpen {
      idleMicroScheduler.setSchedulingSuspended(false)
    }
  }

  func setNotchPreviewBlend(_ blend: CGFloat) {
    notchPreviewBlend = min(max(blend, 0), 1)
  }

  func clearNotchPreviewBlend() {
    notchPreviewBlend = 0
  }

  func setNotchPullVisual(offset: CGSize, tension: CGFloat) {
    notchPullVisualOffset = offset
    notchPullTension = min(max(tension, 0), 1)
  }

  func clearNotchPullVisual() {
    notchPullVisualOffset = .zero
    notchPullTension = 0
    notchUndockTrembleOffset = .zero
  }

  func noteHide() {
    stop()
  }

  func noteUserInteraction() {
    let now = Date()
    if isLaunchGreetingPhase {
      cancelLaunchGreeting()
    }
    lastMeaningfulMovementAt = now
    lastCursorMovementAt = now
    lastSampledScreenPoint = NSEvent.mouseLocation
    if case .sleepyTransition = phase {
      cancelSleepyTransition()
    } else {
      wakeIfNeeded()
    }
  }

  func beginDrag() {
    cancelLaunchGreeting()
    isDragging = true
    dragStartedAt = Date()
    dragPhysics.begin()
    dragFaceLagOffset = .zero
    postDragDazedStartedAt = nil
    noteUserInteraction()
    phase = .dragging
    wakeSequenceStartedAt = nil
    sleepyTransitionEnteredAt = nil
  }

  func noteDragStep(screenDelta: CGSize, sampleTime: Date = Date(), totalDistance: CGFloat = 0) {
    guard isDragging else { return }
    dragPhysics.ingest(screenDelta: screenDelta, sampleTime: sampleTime)
    dragPhysicsRenderTick &+= 1
    lastMeaningfulMovementAt = Date()
    _ = totalDistance
  }

  func endDrag(metrics: OrbyDragGestureMetrics, forcedUndock: Bool = false, forceNormal: Bool = false) {
    isDragging = false
    dragStartedAt = nil
    lastMeaningfulMovementAt = Date()

    let dazed: Bool
    if forcedUndock {
      dazed = true
    } else if forceNormal {
      dazed = false
    } else {
      let classification = OrbyDragGestureClassifier.classify(metrics)
      if case .dazed = classification { dazed = true } else { dazed = false }
    }
    dragPhysics.release(dazed: dazed)

    if dazed {
      postDragDazedStartedAt = Date()
      phase = .postDragDazed(progress: 0)
    } else {
      phase = isHovering ? .hoverExcited : .awake
    }
    clearNotchPullVisual()
  }

  func setHovering(_ hovering: Bool) {
    let wasHovering = isHovering
    isHovering = hovering
    if isLaunchGreetingPhase {
      pendingHoverExcitedAfterGreeting = hovering
      return
    }
    if hovering {
      idleMicroScheduler.cancelActiveForInteraction(now: Date(), mood: lastResolvedMood)
      if case .asleep = phase {
        noteUserInteraction()
      } else if case .sleepyTransition = phase {
        noteUserInteraction()
      }
      if !isDragging, !isWakePhase, !isPostDragDazedPhase {
        phase = .hoverExcited
      }
    } else if wasHovering, !isDragging, !isWakePhase, !isPostDragDazedPhase {
      phase = .awake
    }
  }

  func updateOrbHover(panel: NSPanel) {
    guard !isDragging, !isContextMenuOpen else { return }
    let inside = OrbyOrbGeometry.isCursorInsideOrb(panel: panel)
    if inside != isHovering {
      setHovering(inside)
    }
  }

  func noteContextMenuOpened() {
    cancelLaunchGreeting()
    isContextMenuOpen = true
    noteUserInteraction()
  }

  func noteContextMenuClosed() {
    isContextMenuOpen = false
    lastMeaningfulMovementAt = Date()
  }

  func presentation(resolvedMood: OrbyMood, intensity: OrbyEmotionIntensity) -> OrbyMiniVisualPresentation {
    // Avoid writing to observable properties inside view body evaluation.
    if lastResolvedMood != resolvedMood { lastResolvedMood = resolvedMood }
    _ = idleMicroRenderTick
    _ = notchVisualRenderTick
    _ = dragPhysicsRenderTick
    _ = sleepBreathRenderTick
    _ = ambientSkyRenderTick
    let now = Date()
    var sleepBreath = 0.0
    let deformation = dragPhysics.snapshot()
    let currentDragFaceLag = deformation.faceLagOffset
    let effectivePhase = prioritizedPhase()

    let (presentationMood, presentationIntensity) = (resolvedMood, intensity)

    let tracking = eyeTrackingFactor(for: effectivePhase)
    var closure = resolvedEyelidClosure(for: effectivePhase)
    var scripted = scriptedEyeOffset(for: effectivePhase)
    let excited = effectivePhase == .hoverExcited
    var emotionBase = OrbyEmotionCompositor.compose(
      mood: presentationMood,
      intensity: presentationIntensity,
      phase: effectivePhase,
      eyelidClosure: closure,
      isExcited: excited
    )
    if notchPullTension > 0 {
      emotionBase = OrbyNotchResistanceAppearance.apply(tension: notchPullTension, to: emotionBase)
    }

    var idleOverlay = OrbyIdleMicroOverlay()
    var idleNudge = CGSize.zero
    var idleTilt = 0.0
    var idleOrbScale: CGFloat = 1
    var headYExtra = 0.0
    var headXExtra = 0.0

    if let idleFrame = idleMicroScheduler.currentFrame(baseMouth: emotionBase.mouth), wakeMouthCrossfade >= 1 {
      emotionBase = OrbyIdleMicrobehaviorAnimation.apply(idleFrame, to: emotionBase)
      scripted = CGSize(
        width: scripted.width + idleFrame.scriptedEyeOffset.width,
        height: scripted.height + idleFrame.scriptedEyeOffset.height
      )
      if let microClosure = idleFrame.eyelidClosure {
        closure = max(closure, microClosure)
      }
      idleOverlay = idleFrame.overlay
      idleNudge = idleFrame.faceNudge
      idleTilt = idleFrame.faceTiltDegrees
      idleOrbScale = idleFrame.extraOrbScale
      headYExtra = idleFrame.headTurnYExtra
      headXExtra = idleFrame.headTurnXExtra
      if let trackingOverride = idleFrame.trackingFactor {
        emotionBase.trackingScale *= trackingOverride
      }
    }

    if case .wakingYawn(let progress) = effectivePhase {
      let arc = OrbyWakeYawnMotion.headTurn(progress: progress)
      headXExtra = arc.x
      headYExtra = arc.y
    } else if case .launchGreeting(let progress) = effectivePhase {
      headXExtra = OrbyLaunchGreetingAnimator.headTurnX(progress: progress)
      headYExtra = OrbyLaunchGreetingAnimator.headTurnY(progress: progress)
    }

    if case .launchGreeting = effectivePhase {
      // Mouth is progress-driven in compositor; skip mood settle.
      lastRenderedMouth = emotionBase.mouth
    } else {
      emotionBase.mouth = resolvedMouth(
        composed: emotionBase.mouth,
        phase: effectivePhase
      )
      lastRenderedMouth = emotionBase.mouth
    }

    // Subtle "breathing with his mouth slightly open" while asleep: a slow
    // ~4.2s inhale/exhale that gently parts the lips and swells the orb. Kept
    // inside the rounded-blob family (oval wider than tall) so the shape only
    // grows/shrinks — it never swaps form. Captured into `lastRenderedMouth`
    // so the wake ritual can morph straight out of it.
    // Breath oscillation runs whenever there's any sleep depth (asleep + the
    // early wake ritual) so the orb's breathing swell can ease back to rest as
    // the yawn finishes; the mouth only breathes while fully asleep.
    if OrbySleepDepth.depth(for: effectivePhase) > 0 {
      sleepBreath = (sin(now.timeIntervalSinceReferenceDate * (2 * .pi / 4.2)) + 1) / 2 // 0…1
    }
    if case .asleep = effectivePhase, wakeMouthCrossfade >= 1 {
      // Prominent "open-mouth breathing": on inhale the mouth swells from a thin
      // line into a soft filled circle, then deflates back to a line on exhale.
      // Stays in the rounded-blob family (openness = 0) — we just shrink the width
      // and grow the height — so it never flips into the vertical yawn capsule.
      //
      // For the first `asleepMouthLineHoldSeconds` after falling asleep the mouth
      // holds a flat line; only then does the breathing begin, easing out of that
      // same line so there's no jump.
      let hold = OrbyMiniVisualTiming.asleepMouthLineHoldSeconds
      let asleepElapsed = asleepEnteredAt.map { now.timeIntervalSince($0) } ?? hold
      var m = emotionBase.mouth
      m.openness = 0
      m.cornerLift = 0
      m.curvature = 0.5
      if asleepElapsed < hold {
        // Flat resting line.
        m.width = 11.0
        m.lineHeight = 2.4
        sleepBreath = 0
      } else {
        // Local breath phase that starts at 0 (fully exhaled line) the instant the
        // hold ends, so breathing eases up from the line rather than snapping in.
        let breathTime = asleepElapsed - hold
        let breath = CGFloat((1 - cos(breathTime * (2 * .pi / 4.2))) / 2) // 0 → 1 …
        sleepBreath = Double(breath)
        m.width = 11.0 - 6.0 * breath      // wide line → narrow
        m.lineHeight = 2.4 + 6.6 * breath  // thin → ~9 (round filled blob)
      }
      emotionBase.mouth = m
      lastRenderedMouth = m
    }

    let cheekBlush = OrbyCheekBlushPolicy.resolvedStrength(
      phase: effectivePhase,
      compositorStrength: emotionBase.cheekBlushStrength,
      idleMicro: idleMicroScheduler.active?.kind
    )

    let trackingScale = emotionBase.trackingScale * tracking
    let cursorOffset = CGSize(
      width: cursorEyeOffset.width * trackingScale,
      height: cursorEyeOffset.height * trackingScale
    )
    let headFactor = headTrackingFactor(for: effectivePhase)
    let glanceHeadY = scriptedHeadTurnY(for: effectivePhase)
    let blinkAllowed = allowsAmbientBlink(for: effectivePhase, now: now)
      && idleMicroScheduler.allowsBaselineBlink(now: now)

    let skyContext = ambientSkySchedulingContext(
      phase: effectivePhase,
      mood: resolvedMood,
      now: now,
      dayNightBlend: CGFloat(idleOverlay.animeEyeReveal)
    )
    let ambientSkyMeteors = OrbySurfaceFormBehavior.usesAmbientSkyMeteors(surfaceForm)
      ? ambientSkyScheduler.renderItems(now: now, context: skyContext)
      : []
    let notchScale = resolvedNotchOrbScale()
    let combinedDragLag = currentDragFaceLag

    return OrbyMiniVisualPresentation(
      resolvedMood: presentationMood,
      intensity: presentationIntensity,
      phase: effectivePhase,
      emotion: emotionBase,
      cursorEyeOffset: cursorOffset,
      scriptedEyeOffset: scripted,
      dragFaceLagOffset: combinedDragLag,
      dragDeformation: deformation,
      dragFaceDeformationStrength: dragPhysics.faceDeformationStrength,
      headTurnXDegrees: headTurnXDegrees * headFactor + headXExtra,
      headTurnYDegrees: headTurnYDegrees * headFactor + glanceHeadY + headYExtra,
      eyeTrackingFactor: tracking,
      eyelidClosure: closure,
      bezelOnDarkBackground: bezelOnDarkBackground,
      backgroundLuminance: backgroundLuminance,
      breathingScale: breathingScale(for: effectivePhase),
      zzzOpacity: zzzOpacity(for: effectivePhase),
      dazedHaloOpacity: dazedHaloOpacity(for: effectivePhase),
      orbScale: orbScale(for: effectivePhase) * idleOrbScale * notchScale,
      isExcited: excited,
      isDragging: isDragging,
      allowsAmbientBlink: blinkAllowed,
      ambientBlinkInterval: OrbyMiniVisualTiming.ambientBlinkInterval(for: resolvedMood),
      idleMicro: idleMicroScheduler.active,
      idleMicroOverlay: idleOverlay,
      idleFaceNudge: idleNudge,
      idleFaceTiltDegrees: idleTilt,
      idleExtraOrbScale: idleOrbScale,
      wakeMouthCrossfade: wakeMouthCrossfade,
      cheekBlushStrength: cheekBlush,
      sleepBreath: sleepBreath,
      // Day sky is NOT clock-driven — Orby is always night by default. It only
      // blooms to day (and back) during the anime self-satisfied beat, tied to
      // that behavior's reveal envelope.
      dayNightBlend: CGFloat(idleOverlay.animeEyeReveal),
      ambientSkyMeteors: ambientSkyMeteors,
      materialSimplified: OrbySurfaceFormBehavior.usesSimplifiedOrbMaterial(surfaceForm)
    )
  }

  private func ambientSkySchedulingContext(
    phase: OrbyMiniVisualPhase,
    mood: OrbyMood,
    now: Date,
    dayNightBlend: CGFloat
  ) -> OrbyAmbientSkySchedulingContext {
    OrbyAmbientSkySchedulingContext(
      phase: phase,
      mood: mood,
      isVisible: panel?.isVisible == true,
      isDragging: isDragging,
      isContextMenuOpen: isContextMenuOpen,
      dayNightBlend: dayNightBlend,
      zzzOpacity: zzzOpacity(for: phase),
      activeMicrobehavior: idleMicroScheduler.active?.kind
    )
  }

  private func updateAmbientSkyEvents(now: Date, mood: OrbyMood, phase: OrbyMiniVisualPhase) {
    let dayNight: CGFloat = {
      guard idleMicroScheduler.active?.kind == .animeSelfSatisfied,
            let frame = idleMicroScheduler.currentFrame(
              baseMouth: OrbyEmotionAppearance.neutralDefault.mouth
            ) else { return 0 }
      return CGFloat(frame.overlay.animeEyeReveal)
    }()
    let context = ambientSkySchedulingContext(
      phase: phase,
      mood: mood,
      now: now,
      dayNightBlend: dayNight
    )
    let hadActive = ambientSkyScheduler.hasActiveEvents
    ambientSkyScheduler.advance(now: now, context: context)
    if ambientSkyScheduler.hasActiveEvents || hadActive {
      ambientSkyRenderTick &+= 1
    }
  }

  private func isWakePhaseForMouth(_ phase: OrbyMiniVisualPhase) -> Bool {
    switch phase {
    case .wakingQuickBlink, .wakingYawn, .wakingDoubleBlink, .wakingSquint,
         .wakingGlanceRight, .wakingGlanceLeft:
      true
    default:
      false
    }
  }

  private func usesProgressDrivenMouth(_ phase: OrbyMiniVisualPhase) -> Bool {
    switch phase.mouthPhaseKind {
    case .postDragDazed, .sleepyTransition, .waking, .launchGreeting:
      true
    case .awake, .hoverExcited, .dragging, .asleep:
      false
    }
  }

  private func shouldAutoMouthSettle(into kind: OrbyMouthPhaseKind) -> Bool {
    switch kind {
    case .awake, .hoverExcited, .dragging, .asleep:
      true
    case .postDragDazed, .sleepyTransition, .waking, .launchGreeting:
      false
    }
  }

  private func resolvedMouth(composed: OrbyMouthParameters, phase: OrbyMiniVisualPhase) -> OrbyMouthParameters {
    let kind = phase.mouthPhaseKind
    let previousKind = mouthSettleTrackedKind
    if mouthSettleTrackedKind != kind {
      // Leaving sleep into the wake ritual: capture the live (breathing) mouth
      // so the first wake motion morphs out of it instead of snapping shut.
      if previousKind == .asleep, kind == .waking {
        wakeEntryMouth = lastRenderedMouth
        wakeEntryStartedAt = Date()
      }
      if mouthSettleTrackedKind != nil, shouldAutoMouthSettle(into: kind) {
        beginMouthSettle(from: lastRenderedMouth, to: composed, kind: kind)
      } else {
        mouthSettleTrackedKind = kind
        wakeMouthCrossfade = 1
        wakeMouthCrossfadeStartedAt = nil
      }
    } else if mouthSettleTrackedKind == nil {
      mouthSettleTrackedKind = kind
    }

    if wakeMouthCrossfade < 1, !usesProgressDrivenMouth(phase) {
      return smileAwareMouthInterpolated(
        from: wakeMouthCrossfadeFrom,
        to: wakeMouthCrossfadeTo,
        progress: wakeMouthCrossfade,
        targetKind: kind
      )
    }

    // Smoothly morph from the breathing mouth into the (progress-driven) wake
    // mouth over a short crossfade, regardless of the breathing shape.
    if kind == .waking, let entry = wakeEntryMouth, let start = wakeEntryStartedAt {
      let elapsed = Date().timeIntervalSince(start)
      let t = OrbyMiniVisualEasing.smoothstep(
        min(max(elapsed / OrbyMiniVisualTiming.wakeMouthCrossfadeSeconds, 0), 1)
      )
      if t >= 1 {
        wakeEntryMouth = nil
        wakeEntryStartedAt = nil
        return composed
      }
      return OrbyMouthParameters.interpolated(from: entry, to: composed, progress: t)
    }

    return composed
  }

  private func smileAwareMouthInterpolated(
    from a: OrbyMouthParameters,
    to b: OrbyMouthParameters,
    progress: Double,
    targetKind: OrbyMouthPhaseKind
  ) -> OrbyMouthParameters {
    guard targetKind == .hoverExcited || b.cornerLift >= 4.5 else {
      return OrbyMouthParameters.interpolated(from: a, to: b, progress: progress)
    }
    let t = min(max(progress, 0), 1)
    let liftT = OrbyMiniVisualEasing.smoothstep(min(max(t / 0.42, 0), 1))
    let widthT = OrbyMiniVisualEasing.smoothstep(min(max((t - 0.24) / 0.76, 0), 1))
    let openT = OrbyMiniVisualEasing.smoothstep(t)
    return OrbyMouthParameters(
      width: a.width + (b.width - a.width) * CGFloat(widthT),
      lineHeight: a.lineHeight + (b.lineHeight - a.lineHeight) * CGFloat(openT),
      cornerLift: a.cornerLift + (b.cornerLift - a.cornerLift) * CGFloat(liftT),
      curvature: a.curvature + (b.curvature - a.curvature) * CGFloat(liftT),
      openness: a.openness + (b.openness - a.openness) * CGFloat(openT),
      ovalWidth: a.ovalWidth + (b.ovalWidth - a.ovalWidth) * CGFloat(openT),
      ovalHeight: a.ovalHeight + (b.ovalHeight - a.ovalHeight) * CGFloat(openT),
      verticalOffset: a.verticalOffset + (b.verticalOffset - a.verticalOffset) * CGFloat(openT)
    )
  }

  private func beginMouthSettle(
    from: OrbyMouthParameters,
    to: OrbyMouthParameters,
    kind: OrbyMouthPhaseKind
  ) {
    wakeMouthCrossfadeFrom = from
    wakeMouthCrossfadeTo = to
    wakeMouthCrossfade = 0
    wakeMouthCrossfadeStartedAt = Date()
    mouthSettleTrackedKind = kind
  }

  private func updateIdleMicrobehaviors(now: Date, mood: OrbyMood, phase: OrbyMiniVisualPhase) {
    guard OrbySurfaceFormBehavior.allowsIdleMicrobehaviors(surfaceForm) else {
      idleMicroScheduler.setSchedulingSuspended(true)
      return
    }
    idleMicroScheduler.setSchedulingSuspended(
      OrbyIdleMicrobehaviorPolicy.schedulingSuspended(
        for: phase,
        isContextMenuOpen: isContextMenuOpen
      ) || wakeMouthCrossfade < 1
    )
    let hadActive = idleMicroScheduler.active != nil
    idleMicroScheduler.advance(now: now, mood: mood)
    if idleMicroScheduler.active != nil {
      idleMicroRenderTick &+= 1
    } else if hadActive {
      idleMicroRenderTick &+= 1
    }
    let idleSeconds = now.timeIntervalSince(lastMeaningfulMovementAt)
    let untilSleep = max(0, OrbyMiniVisualTiming.cursorSleepThresholdSeconds - idleSeconds)
    let context = OrbyIdleMicroContext(
      mood: mood,
      phase: phase,
      isVisible: panel?.isVisible == true,
      isHovering: isHovering,
      isDragging: isDragging,
      isContextMenuOpen: isContextMenuOpen,
      cursorInsideOrb: isHovering,
      secondsUntilSleepThreshold: untilSleep
    )
    // A running microbehavior is never paused by cursor movement (advance() above
    // keeps it going). But we hold off *starting* the next one while Orby is still
    // watching the cursor — i.e. his eyes are offset from center or the cursor moved
    // very recently. Only once his gaze has settled back to the default position do
    // we let the scheduler pick the next behavior.
    if gazeAtRest(now: now) {
      idleMicroScheduler.trySchedule(now: now, context: context, mood: mood)
    }
  }

  /// True when Orby's eyes have returned to (about) center and the cursor hasn't moved
  /// for a short beat — i.e. he's back to his default face position, not actively watching.
  private func gazeAtRest(now: Date) -> Bool {
    let offset = hypot(cursorEyeOffset.width, cursorEyeOffset.height)
    let settledOffset = offset < 0.5
    let cursorQuiet = now.timeIntervalSince(lastCursorMovementAt) > 0.35
    return settledOffset && cursorQuiet
  }
}

// MARK: - Loop

private extension OrbyMiniVisualController {
  var isWakePhase: Bool {
    switch phase {
    case .wakingQuickBlink, .wakingYawn, .wakingDoubleBlink, .wakingSquint,
         .wakingGlanceRight, .wakingGlanceLeft:
      true
    default:
      false
    }
  }

  func tick() {
    guard let panel, panel.isVisible else { return }
    let now = Date()
    tickCounter &+= 1

    if OrbySurfaceFormBehavior.samplesBezelFromBackground(surfaceForm) {
      updateBezelAppearance(panel: panel)
    }
    sampleCursor(relativeTo: panel)
    updateOrbHover(panel: panel)
    updateDragPhysicsFrame()
    updateWakeMouthCrossfade(now: now)
    advanceLaunchGreeting(now: now)
    if !isLaunchGreetingPhase {
      advanceSleepWake(now: now)
      updatePriorityPhase(now: now)
    }
    updateIdleMicrobehaviors(now: now, mood: lastResolvedMood, phase: prioritizedPhase())
    if notchPullTension > 0 {
      updateNotchUndockTremble(now: now)
    } else if notchUndockTrembleOffset != .zero {
      notchUndockTrembleOffset = .zero
      notchVisualRenderTick &+= 1
    }
    if OrbySurfaceFormBehavior.usesAmbientSkyMeteors(surfaceForm) {
      updateAmbientSkyEvents(now: now, mood: lastResolvedMood, phase: prioritizedPhase())
    }

    if case .asleep = prioritizedPhase() {
      sleepBreathRenderTick &+= 1
    }

    // Adaptive tick rate: drop to 10 fps when idle to save CPU.
    let wantsActive = needsActiveTickRate()
    let desiredInterval = wantsActive ? Self.activeInterval : Self.idleInterval
    if abs(currentTimerInterval - desiredInterval) > 0.001 {
      installTimer(interval: desiredInterval)
    }
  }

  func updateDragPhysicsFrame() {
    guard dragPhysics.needsFrameUpdates else { return }
    dragPhysics.advanceFrame(dt: currentTimerInterval)
    let snap = dragPhysics.snapshot()
    if snap.faceLagOffset != dragFaceLagOffset {
      dragFaceLagOffset = snap.faceLagOffset
    }
    dragPhysicsRenderTick &+= 1
  }

  func resolvedEyelidClosure(for phase: OrbyMiniVisualPhase) -> Double {
    let target = eyelidClosure(for: phase)
    if case .sleepyTransition = phase {
      let smooth = OrbyMiniVisualTiming.sleepyEyelidSmoothingPerFrame
      smoothedEyelidClosure += (target - smoothedEyelidClosure) * smooth
      return smoothedEyelidClosure
    }
    smoothedEyelidClosure = target
    return target
  }

  func sampleCursor(relativeTo panel: NSPanel) {
    let now = Date()
    let mouseScreen = NSEvent.mouseLocation

    if let last = lastSampledScreenPoint {
      let dx = mouseScreen.x - last.x
      let dy = mouseScreen.y - last.y
      if hypot(dx, dy) >= OrbyMiniVisualTiming.meaningfulCursorDelta {
        lastMeaningfulMovementAt = now
        lastCursorMovementAt = now
        switch phase {
        case .sleepyTransition:
          cancelSleepyTransition()
        case .asleep:
          wakeIfNeeded()
        default:
          break
        }
      }
    }
    lastSampledScreenPoint = mouseScreen

    guard let contentView = panel.contentView else { return }
    let trackView = contentView.subviews.first ?? contentView

    let mouseInWindow = panel.convertPoint(fromScreen: mouseScreen)
    let local = trackView.convert(mouseInWindow, from: nil)
    let center = CGPoint(x: trackView.bounds.midX, y: trackView.bounds.midY)

    var deltaX = local.x - center.x
    var deltaY = local.y - center.y
    if !trackView.isFlipped {
      deltaY = -deltaY
    }

    let distance = hypot(deltaX, deltaY)
    let ref = OrbyMiniVisualTiming.cursorTrackingReferenceDistance
    let strength = min(distance / ref, 1)

    let maxE = OrbyMiniVisualTiming.maxEyeOffset
    if distance > 0.5 {
      let nx = (deltaX / distance) * strength
      let ny = (deltaY / distance) * strength
      targetEyeOffset = CGSize(width: nx * maxE, height: ny * maxE)
    } else {
      targetEyeOffset = .zero
    }

    if distance > 0.5 {
      let nx = (deltaX / distance) * strength
      let ny = (deltaY / distance) * strength
      targetHeadTurnY = Double(nx) * OrbyMiniVisualTiming.maxHeadTurnYDegrees
      targetHeadTurnX = Double(-ny) * OrbyMiniVisualTiming.maxHeadTurnXDegrees
    } else {
      targetHeadTurnY = 0
      targetHeadTurnX = 0
    }

    updateDisplayedCursorFollow(now: now)
  }

  func updateDisplayedCursorFollow(now: Date) {
    let canFollow = eyeTrackingFactor(for: prioritizedPhase()) > 0.01
      && !isWakePhase
    guard canFollow else {
      if case .postDragDazed = phase, !isDragging { return }
      cursorEyeOffset = .zero
      headTurnXDegrees = 0
      headTurnYDegrees = 0
      return
    }

    let idleSinceMove = now.timeIntervalSince(lastCursorMovementAt)
    let smoothing = OrbyMiniVisualTiming.eyeFollowSmoothingPerFrame

    if idleSinceMove <= OrbyMiniVisualTiming.cursorTrackingIdleSeconds {
      gazeHoldEyeOffset = nil
      cursorEyeOffset = blend(cursorEyeOffset, targetEyeOffset, smoothing)
      headTurnXDegrees = blend(headTurnXDegrees, targetHeadTurnX, smoothing)
      headTurnYDegrees = blend(headTurnYDegrees, targetHeadTurnY, smoothing)
    } else if idleSinceMove <= OrbyMiniVisualTiming.cursorGazeHoldSeconds {
      if gazeHoldEyeOffset == nil {
        gazeHoldEyeOffset = cursorEyeOffset
      }
      cursorEyeOffset = gazeHoldEyeOffset ?? cursorEyeOffset
    } else {
      gazeHoldEyeOffset = nil
      let decay = OrbyMiniVisualTiming.eyeReturnDecayPerFrame
      var offset = cursorEyeOffset
      offset.width *= decay
      offset.height *= decay
      if abs(offset.width) < 0.12 { offset.width = 0 }
      if abs(offset.height) < 0.12 { offset.height = 0 }
      cursorEyeOffset = offset

      headTurnXDegrees *= decay
      headTurnYDegrees *= decay
      if abs(headTurnXDegrees) < 0.15 { headTurnXDegrees = 0 }
      if abs(headTurnYDegrees) < 0.15 { headTurnYDegrees = 0 }
    }
  }

  func blend(_ current: CGSize, _ target: CGSize, _ factor: Double) -> CGSize {
    let f = factor
    return CGSize(
      width: current.width + (target.width - current.width) * f,
      height: current.height + (target.height - current.height) * f
    )
  }

  func blend(_ current: Double, _ target: Double, _ factor: Double) -> Double {
    current + (target - current) * factor
  }

  func advanceSleepWake(now: Date) {
    guard !isDragging, !isContextMenuOpen else { return }

    switch phase {
    case .postDragDazed:
      if let start = postDragDazedStartedAt {
        let p = progress(since: start, duration: OrbyMiniVisualTiming.postDragDazedDurationSeconds)
        if p >= 1 {
          postDragDazedStartedAt = nil
          finishPostDragDazed(to: isHovering ? .hoverExcited : .awake)
        } else {
          phase = .postDragDazed(progress: p)
        }
      }
    case .wakingQuickBlink:
      if let start = wakeSequenceStartedAt {
        let p = progress(since: start, duration: OrbyMiniVisualTiming.wakingQuickBlinkDurationSeconds)
        if p >= 1 {
          finishWake(to: isHovering ? .hoverExcited : .awake)
        } else {
          phase = .wakingQuickBlink(progress: p)
        }
      }
    case .wakingYawn:
      if let start = wakeSequenceStartedAt {
        let p = progress(since: start, duration: OrbyMiniVisualTiming.wakingYawnDurationSeconds)
        if p >= 1 {
          advanceWakeStepAfterGap(
            now: now,
            holdAtEnd: { .wakingYawn(progress: 1) },
            handoff: .nextPhase(.wakingDoubleBlink(progress: 0))
          )
        } else {
          clearWakePhaseGap()
          phase = .wakingYawn(progress: p)
        }
      }
    case .wakingDoubleBlink:
      if let start = wakeSequenceStartedAt {
        let p = progress(since: start, duration: OrbyMiniVisualTiming.wakingDoubleBlinkDurationSeconds)
        if p >= 1 {
          advanceWakeStepAfterGap(
            now: now,
            holdAtEnd: { .wakingDoubleBlink(progress: 1) },
            handoff: .nextPhase(.wakingSquint(progress: 0))
          )
        } else {
          clearWakePhaseGap()
          phase = .wakingDoubleBlink(progress: p)
        }
      }
    case .wakingSquint:
      if let start = wakeSequenceStartedAt {
        let p = progress(since: start, duration: OrbyMiniVisualTiming.wakingSquintDurationSeconds)
        if p >= 1 {
          advanceWakeStepAfterGap(
            now: now,
            holdAtEnd: { .wakingSquint(progress: 1) },
            handoff: .nextPhase(.wakingGlanceRight(progress: 0))
          )
        } else {
          clearWakePhaseGap()
          phase = .wakingSquint(progress: p)
        }
      }
    case .wakingGlanceRight:
      if let start = wakeSequenceStartedAt {
        let p = progress(since: start, duration: OrbyMiniVisualTiming.wakingGlanceRightDurationSeconds)
        if p >= 1 {
          advanceWakeStepAfterGap(
            now: now,
            holdAtEnd: { .wakingGlanceRight(progress: 1) },
            handoff: .nextPhase(.wakingGlanceLeft(progress: 0))
          )
        } else {
          clearWakePhaseGap()
          phase = .wakingGlanceRight(progress: p)
        }
      }
    case .wakingGlanceLeft:
      if let start = wakeSequenceStartedAt {
        let p = progress(since: start, duration: OrbyMiniVisualTiming.wakingGlanceLeftDurationSeconds)
        if p >= 1 {
          advanceWakeStepAfterGap(
            now: now,
            holdAtEnd: { .wakingGlanceLeft(progress: 1) },
            handoff: .finish
          )
        } else {
          clearWakePhaseGap()
          phase = .wakingGlanceLeft(progress: p)
        }
      }
    default:
      break
    }
  }

  func updatePriorityPhase(now: Date) {
    if isDragging {
      phase = .dragging
      return
    }
    if isContextMenuOpen {
      return
    }
    if isLaunchGreetingPhase { return }
    if isWakePhase || isPostDragDazedPhase { return }

    if isHovering {
      phase = .hoverExcited
      return
    }

    let idle = now.timeIntervalSince(lastMeaningfulMovementAt)
  if idle < OrbyMiniVisualTiming.cursorSleepThresholdSeconds {
      if case .sleepyTransition = phase {
        phase = .awake
        sleepyTransitionEnteredAt = nil
      } else if phase == .asleep {
        phase = .awake
        asleepEnteredAt = nil
      }
      return
    }

    if phase == .asleep { return }

    let transitionStart = sleepyTransitionEnteredAt
      ?? {
        let entered = now.addingTimeInterval(-(idle - OrbyMiniVisualTiming.cursorSleepThresholdSeconds))
        sleepyTransitionEnteredAt = entered
        return entered
      }()

    let elapsed = now.timeIntervalSince(transitionStart)
    let progress = min(max(elapsed / OrbyMiniVisualTiming.sleepyTransitionDurationSeconds, 0), 1)
    if progress >= 1 {
      if phase != .asleep { asleepEnteredAt = now }
      phase = .asleep
    } else {
      phase = .sleepyTransition(progress: progress)
    }
  }

  func prioritizedPhase() -> OrbyMiniVisualPhase {
    if isDragging { return .dragging }
    if isContextMenuOpen { return isHovering ? .hoverExcited : .awake }
    if isPostDragDazedPhase { return phase }
    if isLaunchGreetingPhase { return phase }
    if isHovering, !isWakePhase, phase != .asleep, !isSleepyPhase {
      return .hoverExcited
    }
    return phase
  }

  var isLaunchGreetingPhase: Bool {
    if case .launchGreeting = phase { return true }
    return false
  }

  func shouldPlayLaunchGreeting() -> Bool {
    OrbySurfaceFormBehavior.allowsLaunchGreeting(surfaceForm)
  }

  func startLaunchGreeting() {
    launchGreetingStartedAt = Date()
    pendingHoverExcitedAfterGreeting = isHovering
    mouthSettleTrackedKind = .launchGreeting
    wakeMouthCrossfade = 1
    wakeMouthCrossfadeStartedAt = nil
    phase = .launchGreeting(progress: 0)
    lastMeaningfulMovementAt = Date()
    lastCursorMovementAt = Date()
  }

  func advanceLaunchGreeting(now: Date) {
    guard let start = launchGreetingStartedAt else { return }
    let duration = OrbyMiniVisualTiming.launchGreetingDurationSeconds
    let p = progress(since: start, duration: duration)
    if p >= 1 {
      completeLaunchGreeting()
    } else {
      phase = .launchGreeting(progress: p)
    }
  }

  func completeLaunchGreeting() {
    launchGreetingStartedAt = nil
    let delay = Double.random(
      in: OrbyMiniVisualTiming.postIdleBlinkDelayRange
    )
    baselineBlinkResumeAt = Date().addingTimeInterval(delay)
    lastMeaningfulMovementAt = Date()
    lastCursorMovementAt = Date()
    let next: OrbyMiniVisualPhase =
      (pendingHoverExcitedAfterGreeting || isHovering) ? .hoverExcited : .awake
    pendingHoverExcitedAfterGreeting = false
    phase = next
    mouthSettleTrackedKind = nil
  }

  func cancelLaunchGreeting() {
    guard isLaunchGreetingPhase else { return }
    launchGreetingStartedAt = nil
    pendingHoverExcitedAfterGreeting = isHovering
    mouthSettleTrackedKind = nil
    phase = isHovering ? .hoverExcited : .awake
  }

  var isPostDragDazedPhase: Bool {
    if case .postDragDazed = phase { return true }
    return false
  }

  var isSleepyPhase: Bool {
    if case .sleepyTransition = phase { return true }
    return false
  }

  /// Ends sleepy transition immediately when the cursor moves again (no yawn / wake ritual).
  func cancelSleepyTransition() {
    guard case .sleepyTransition = phase else { return }
    sleepyTransitionEnteredAt = nil
    smoothedEyelidClosure = 0
    wakeSequenceStartedAt = nil
    phase = isHovering ? .hoverExcited : .awake
  }

  func wakeIfNeeded() {
    switch phase {
    case .sleepyTransition:
      cancelSleepyTransition()
    case .asleep:
      startFullWake()
    case .postDragDazed:
      postDragDazedStartedAt = nil
      phase = isHovering ? .hoverExcited : .awake
    default:
      if isWakePhase { return }
      break
    }
  }

  func startQuickBlink() {
    clearWakePhaseGap()
    wakeSequenceStartedAt = Date()
    phase = .wakingQuickBlink(progress: 0)
  }

  func startFullWake() {
    clearWakePhaseGap()
    asleepEnteredAt = nil
    wakeSequenceStartedAt = Date()
    // Do NOT pre-stamp the mouth here. Leaving `mouthSettleTrackedKind` at `.asleep`
    // and preserving the live breathing `lastRenderedMouth` lets `resolvedMouth`
    // detect the asleep → waking transition and smoothly morph the breathing mouth
    // into the yawn (instead of snapping to a closed slit first).
    phase = .wakingYawn(progress: 0)
  }

  func finishWake(to next: OrbyMiniVisualPhase) {
    wakeSequenceStartedAt = nil
    wakePhaseGapEndsAt = nil
    wakeHandoffAfterGap = nil
    sleepyTransitionEnteredAt = nil
    phase = next
  }

  func clearWakePhaseGap() {
    wakePhaseGapEndsAt = nil
    wakeHandoffAfterGap = nil
  }

  /// Hold the finished pose briefly so mouth, head, and eyes do not overlap the next ritual step.
  private func advanceWakeStepAfterGap(
    now: Date,
    holdAtEnd: () -> OrbyMiniVisualPhase,
    handoff: WakeRitualHandoff
  ) {
    if wakeHandoffAfterGap == nil {
      wakeHandoffAfterGap = handoff
      wakePhaseGapEndsAt = now.addingTimeInterval(OrbyMiniVisualTiming.wakePhaseGapSeconds)
      phase = holdAtEnd()
      return
    }
    guard let gapEnd = wakePhaseGapEndsAt, now >= gapEnd else {
      phase = holdAtEnd()
      return
    }
    let pending = wakeHandoffAfterGap
    clearWakePhaseGap()
    switch pending {
    case .nextPhase(let next):
      wakeSequenceStartedAt = now
      phase = next
    case .finish, .none:
      finishWake(to: isHovering ? .hoverExcited : .awake)
    }
  }

  func finishPostDragDazed(to next: OrbyMiniVisualPhase) {
    postDragDazedStartedAt = nil
    wakeSequenceStartedAt = nil
    sleepyTransitionEnteredAt = nil
    phase = next
    onPostDragDazedFinished?()
  }

  func updateWakeMouthCrossfade(now: Date) {
    guard let start = wakeMouthCrossfadeStartedAt else { return }
    let duration = OrbyMiniVisualTiming.wakeMouthCrossfadeSeconds
    let t = min(max(now.timeIntervalSince(start) / duration, 0), 1)
    wakeMouthCrossfade = OrbyMiniVisualEasing.smoothstep(t)
    if t >= 1 {
      wakeMouthCrossfade = 1
      wakeMouthCrossfadeStartedAt = nil
    }
  }

  func progress(since start: Date, duration: TimeInterval) -> Double {
    min(max(Date().timeIntervalSince(start) / duration, 0), 1)
  }

  func resetTransientState() {
    cursorEyeOffset = .zero
    headTurnXDegrees = 0
    headTurnYDegrees = 0
    targetEyeOffset = .zero
    targetHeadTurnX = 0
    targetHeadTurnY = 0
    phase = .awake
    isDragging = false
    isHovering = false
    isContextMenuOpen = false
    wakeSequenceStartedAt = nil
    wakePhaseGapEndsAt = nil
    wakeHandoffAfterGap = nil
    sleepyTransitionEnteredAt = nil
    asleepEnteredAt = nil
    lastSampledScreenPoint = nil
    smoothedEyelidClosure = 0
    gazeHoldEyeOffset = nil
    dragFaceLagOffset = .zero
    dragPhysics.reset()
    postDragDazedStartedAt = nil
    dragStartedAt = nil
    idleMicroScheduler.reset()
    ambientSkyScheduler.noteHide()
    wakeMouthCrossfade = 1
    wakeMouthCrossfadeFrom = OrbyWakeMouthParameters.closedSlit
    wakeMouthCrossfadeTo = OrbyEmotionAppearance.neutralDefault.mouth
    wakeMouthCrossfadeStartedAt = nil
    mouthSettleTrackedKind = nil
    lastRenderedMouth = OrbyEmotionAppearance.neutralDefault.mouth
  }

  func installContextMenuMonitor() {
    guard contextMenuMonitor == nil else { return }
    contextMenuMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown, .rightMouseUp]) { [weak self] event in
      guard let self, let panel = self.panel, panel.isVisible else { return event }
      let mouse = NSEvent.mouseLocation
      if panel.frame.contains(mouse) {
        if event.type == .rightMouseDown {
          self.noteContextMenuOpened()
        } else {
          DispatchQueue.main.async {
            self.noteContextMenuClosed()
          }
        }
      }
      return event
    }
  }

  func removeContextMenuMonitor() {
    if let contextMenuMonitor {
      NSEvent.removeMonitor(contextMenuMonitor)
      self.contextMenuMonitor = nil
    }
  }
}

// MARK: - Presentation mapping

private extension OrbyMiniVisualController {
  func eyeTrackingFactor(for phase: OrbyMiniVisualPhase) -> Double {
    switch phase {
    case .dragging, .asleep, .postDragDazed:
      return 0
    case .wakingYawn, .wakingDoubleBlink, .wakingSquint, .wakingGlanceRight, .wakingGlanceLeft,
         .wakingQuickBlink:
      return 0
    case .launchGreeting(let progress):
      return OrbyLaunchGreetingAnimator.eyeTrackingFactor(progress: progress)
    case .sleepyTransition(let progress):
      return max(0, 1 - progress)
    case .hoverExcited, .awake:
      return 1
    }
  }

  func headTrackingFactor(for phase: OrbyMiniVisualPhase) -> Double {
    switch phase {
    case .dragging, .postDragDazed:
      return 0
    case .asleep, .wakingYawn, .wakingDoubleBlink, .wakingSquint, .wakingGlanceRight,
         .wakingGlanceLeft, .wakingQuickBlink:
      return 0
    case .sleepyTransition(let progress):
      return max(0, 1 - progress) * 0.9
    default:
      return 1
    }
  }

  /// Eye narrow amount: 0 = open, 1 = thin slit (shape morph only — no eyelid overlay).
  func eyelidClosure(for phase: OrbyMiniVisualPhase) -> Double {
    switch phase {
    case .asleep:
      return 1
    case .sleepyTransition(let progress):
      return min(1, max(0, progress) * 0.98)
    case .wakingYawn(let progress):
      return OrbyWakeYawnMotion.eyelidClosure(progress: progress)
    case .wakingDoubleBlink(let progress):
      return wakingDoubleBlinkClosure(progress: progress)
    case .wakingSquint(let progress):
      return wakingSquintClosure(progress: progress)
    case .wakingGlanceRight, .wakingGlanceLeft:
      return 0.44
    case .wakingQuickBlink(let progress):
      return wakingSingleBlinkClosure(progress: progress)
    case .postDragDazed:
      return 0.46
    case .dragging:
      return 0.08
    case .launchGreeting:
      return 0
    default:
      return 0
    }
  }

  func scriptedEyeOffset(for phase: OrbyMiniVisualPhase) -> CGSize {
    switch phase {
    case .launchGreeting(let progress):
      return OrbyLaunchGreetingAnimator.scriptedEyeOffset(progress: progress)
    case .wakingGlanceRight(let progress):
      return wakingGlanceOffset(progress: progress, direction: 1)
    case .wakingGlanceLeft(let progress):
      return wakingGlanceOffset(progress: progress, direction: -1)
    default:
      return .zero
    }
  }

  /// Exactly two shape-morph blinks across 0…1 phase progress.
  func wakingDoubleBlinkClosure(progress: Double) -> Double {
    let blink1 = progress <= 0.48 ? wakingBlinkPulse(progress / 0.48) : 0
    let blink2 = progress >= 0.52 ? wakingBlinkPulse((progress - 0.52) / 0.46) : 0
    return max(blink1, blink2)
  }

  func wakingSingleBlinkClosure(progress: Double) -> Double {
    wakingBlinkPulse(min(max(progress, 0), 1))
  }

  func wakingBlinkPulse(_ t: Double) -> Double {
    guard t >= 0, t <= 1 else { return 0 }
    if t < 0.32 {
      return OrbyMiniVisualEasing.smoothstep(t / 0.32)
    }
    if t < 0.42 {
      return 1
    }
    let opening = (t - 0.42) / 0.58
    return 1 - OrbyMiniVisualEasing.smoothstep(opening)
  }

  func wakingSquintClosure(progress: Double) -> Double {
    if progress < 0.22 {
      let t = OrbyMiniVisualEasing.smoothstep(progress / 0.22)
      return t * 0.72
    }
    if progress < 0.82 {
      return 0.72
    }
    let release = (progress - 0.82) / 0.18
    return 0.72 * (1 - OrbyMiniVisualEasing.smoothstep(release))
  }

  func wakingGlanceOffset(progress: Double, direction: CGFloat) -> CGSize {
    let magnitude: CGFloat = 6.2
    if progress < 0.12 {
      return .zero
    }
    if progress < 0.34 {
      let t = OrbyMiniVisualEasing.smoothstep((progress - 0.12) / 0.22)
      return CGSize(width: magnitude * direction * t, height: 0)
    }
    if progress < 0.78 {
      return CGSize(width: magnitude * direction, height: 0)
    }
    let t = OrbyMiniVisualEasing.smoothstep((progress - 0.78) / 0.22)
    return CGSize(width: magnitude * direction * (1 - t), height: 0)
  }

  func scriptedHeadTurnY(for phase: OrbyMiniVisualPhase) -> Double {
    switch phase {
    case .wakingGlanceRight(let progress):
      return Double(wakingGlanceOffset(progress: progress, direction: 1).width) * 1.15
    case .wakingGlanceLeft(let progress):
      return Double(wakingGlanceOffset(progress: progress, direction: -1).width) * 1.15
    default:
      return 0
    }
  }

  func dazedHaloOpacity(for phase: OrbyMiniVisualPhase) -> Double {
    guard case .postDragDazed(let progress) = phase else { return 0 }
    if progress < 0.09 { return progress / 0.09 }
    if progress < 0.74 { return 1 }
    return 1 - OrbyMiniVisualEasing.smoothstep((progress - 0.74) / 0.26)
  }

  func updateBezelAppearance(panel: NSPanel) {
    let appearance = panel.effectiveAppearance
    let match = appearance.bestMatch(from: [.darkAqua, .aqua])
    let sampled = sampleBackgroundLuminance(behind: panel)
    backgroundLuminance = sampled ?? (match == .darkAqua ? 0.18 : 0.78)
    bezelOnDarkBackground = backgroundLuminance < 0.42
  }

  func sampleBackgroundLuminance(behind panel: NSPanel) -> Double? {
    let frame = panel.frame
    let center = CGPoint(x: frame.midX, y: frame.midY)
    let sampleRect = CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)
    guard
      let image = CGWindowListCreateImage(
        sampleRect,
        [.optionOnScreenBelowWindow],
        CGWindowID(panel.windowNumber),
        [.bestResolution]
      ),
      let dataProvider = image.dataProvider,
      let data = dataProvider.data,
      let bytes = CFDataGetBytePtr(data)
    else {
      return nil
    }

    let width = image.width
    let height = image.height
    let bytesPerRow = image.bytesPerRow
    let bitsPerPixel = image.bitsPerPixel
    guard width > 0, height > 0, bitsPerPixel >= 24 else { return nil }
    let bytesPerPixel = max(bitsPerPixel / 8, 4)
    var total = 0.0
    var count = 0.0
    for y in 0..<height {
      for x in 0..<width {
        let offset = y * bytesPerRow + x * bytesPerPixel
        let b = Double(bytes[offset]) / 255.0
        let g = Double(bytes[offset + 1]) / 255.0
        let r = Double(bytes[offset + 2]) / 255.0
        total += 0.2126 * r + 0.7152 * g + 0.0722 * b
        count += 1
      }
    }
    guard count > 0 else { return nil }
    return total / count
  }

  func breathingScale(for phase: OrbyMiniVisualPhase) -> CGFloat {
    switch phase {
    case .asleep:
      return 1.008
    case .sleepyTransition(let progress):
      let amp = 0.002 + progress * 0.004
      return 1 + amp
    case .wakingYawn:
      return 1.01
    default:
      return 1
    }
  }

  func zzzOpacity(for phase: OrbyMiniVisualPhase) -> Double {
    switch phase {
    case .asleep:
      return 0.72
    case .sleepyTransition(let progress) where progress > 0.82:
      return (progress - 0.82) / 0.18 * 0.35
    default:
      return 0
    }
  }

  func orbScale(for phase: OrbyMiniVisualPhase) -> CGFloat {
    switch phase {
    case .launchGreeting(let progress):
      return OrbyLaunchGreetingAnimator.appearScale(progress: progress)
        * OrbyLaunchGreetingAnimator.smileHoldScale(progress: progress)
        * OrbyLaunchGreetingAnimator.helloPulseScale(progress: progress)
    case .hoverExcited:
      return 1.035
    case .wakingYawn:
      return 1
    case .dragging:
      return 1.01
    default:
      return 1
    }
  }

  func resolvedNotchOrbScale() -> CGFloat {
    if surfaceForm == .notch {
      return OrbyNotchDockingMetrics.dockedOrbScale
    }
    if notchPreviewBlend > 0 {
      // Gradually shrink all the way to docked size as Orby approaches the notch.
      let dockedScale = OrbyNotchDockingMetrics.dockedOrbScale
      return 1 - notchPreviewBlend * (1 - dockedScale)
    }
    return 1
  }

  func updateNotchUndockTremble(now: Date) {
    guard notchPullTension > 0 else {
      if notchUndockTrembleOffset != .zero {
        notchUndockTrembleOffset = .zero
        notchVisualRenderTick &+= 1
      }
      return
    }
    let trembleStart = CGFloat(0.15)
    let normalized = min(max((notchPullTension - trembleStart) / (1 - trembleStart), 0), 1)
    let eased = normalized * normalized * (3 - 2 * normalized)
    // Intense trembling: up to 4px amplitude, high frequency with a second harmonic for jitter.
    let amp = 4.0 * eased
    let t = now.timeIntervalSinceReferenceDate
    let primary = sin(t * 2.0 * .pi * 42.0)
    let secondary = sin(t * 2.0 * .pi * 67.0) * 0.35
    notchUndockTrembleOffset = CGSize(
      width: (primary + secondary) * amp,
      height: sin(t * 2.0 * .pi * 53.0) * amp * 0.25
    )
    notchVisualRenderTick &+= 1
  }

  func allowsAmbientBlink(for phase: OrbyMiniVisualPhase, now: Date) -> Bool {
    guard case .awake = phase else { return false }
    if let resume = baselineBlinkResumeAt, now < resume { return false }
    return true
  }
}

typealias ShrineMiniVisualController = OrbyMiniVisualController
