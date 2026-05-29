import Foundation

/// Tunable Orby visual timing (local UI only; not user settings).
enum OrbyMiniVisualTiming {
  static let cursorSleepThresholdSeconds: TimeInterval = 30
  static let sleepyTransitionDurationSeconds: TimeInterval = 6.0
  static let sleepyTransitionUIAnimationSeconds: TimeInterval = 0.58
  static let sleepyEyelidSmoothingPerFrame: Double = 0.11
  static let earlyWakeTransitionCutoff: Double = 0.35

  /// Yawn: long vertical open with a visible max-mouth hold, then blink / squint / glances.
  static let wakingYawnDurationSeconds: TimeInterval = 4.6
  /// Gentle smile after yawn, before double-blink ritual.
  /// Brief hold at end of each wake step before the next (mouth/head/eyes reset).
  static let wakePhaseGapSeconds: TimeInterval = 0.16
  /// Morph wake slit → resolved mood mouth after the ritual ends.
  static let wakeMouthCrossfadeSeconds: TimeInterval = 0.45
  static let launchGreetingSmileHoldSeconds: TimeInterval = 2.0
  /// Mouth motion (he → llo) + syllables flying to join point.
  static let launchGreetingHelloMotionSeconds: TimeInterval = 1.05
  /// Both syllables hold as assembled “Hello” at the arc peak before fade.
  static let launchGreetingHelloWordHoldSeconds: TimeInterval = 2.0
  static let launchGreetingHelloFadeSeconds: TimeInterval = 0.35
  static let launchGreetingHelloSeconds: TimeInterval =
    launchGreetingHelloMotionSeconds + launchGreetingHelloWordHoldSeconds + launchGreetingHelloFadeSeconds
  static let launchGreetingDurationSeconds: TimeInterval = launchGreetingSmileHoldSeconds + launchGreetingHelloSeconds
  static let launchGreetingAppearSeconds: TimeInterval = 0.46
  /// Default mood / phase mouth morph (not progress-driven wake yawn).
  static let mouthMorphSeconds: TimeInterval = 0.40
  static let wakingDoubleBlinkDurationSeconds: TimeInterval = 0.95
  static let wakingSquintDurationSeconds: TimeInterval = 0.55
  static let wakingGlanceRightDurationSeconds: TimeInterval = 0.62
  static let wakingGlanceLeftDurationSeconds: TimeInterval = 0.62
  static let wakingQuickBlinkDurationSeconds: TimeInterval = 0.28

  static let sleepWakeUIAnimationSeconds: TimeInterval = 0.62
  static let postDragDazedDurationSeconds: TimeInterval = 3.5

  static let cursorSampleInterval: TimeInterval = 1.0 / 60.0
  static let meaningfulCursorDelta: CGFloat = 1.5
  static let cursorTrackingIdleSeconds: TimeInterval = 0.14
  static let cursorGazeHoldSeconds: TimeInterval = 2.0
  static let eyeReturnDecayPerFrame: Double = 0.72
  static let eyeFollowSmoothingPerFrame: Double = 0.62
  static let maxEyeOffset: CGFloat = 6
  static let maxHeadTurnYDegrees: Double = 6
  static let maxHeadTurnXDegrees: Double = 4
  static let cursorTrackingReferenceDistance: CGFloat = 260

  static let maxDragFaceLag: CGFloat = 6
  static let dragFaceLagFactor: CGFloat = 0.38
  static let dragFaceLagSmoothingPerFrame: Double = 0.32

  static let ambientBlinkCloseSeconds: TimeInterval = 0.10
  static let ambientBlinkHoldSeconds: TimeInterval = 0.05
  static let ambientBlinkOpenSeconds: TimeInterval = 0.14
  static let ambientBlinkDoubleGapSeconds: TimeInterval = 0.11
  /// Chance each event is a double blink. Single blinks dominate; doubles are the rarer treat.
  static let ambientDoubleBlinkProbability: Double = 0.22
  /// Keep ambient blinks at their natural, human-like cadence (no extra rarity stretch).
  static let ambientBlinkIntervalRarityMultiplier: Double = 1.0
  /// After idle microbehavior ends, wait before baseline blink resumes.
  static let postIdleBlinkDelayRange: ClosedRange<TimeInterval> = 1.5...3.0

  /// Ambient microbehavior while awake. Hover / sleep / wake / dazed pause it. Tuned to
  /// occur noticeably more often so Orby feels alive (was 10–18 initial / 30–90 cooldown).
  static let idleMicrobehaviorInitialDelayRange: ClosedRange<TimeInterval> = 5...11
  static let idleMicrobehaviorIntervalRange: ClosedRange<TimeInterval> = 16...42
  static let idleMicrobehaviorCooldownRange: ClosedRange<TimeInterval> = 16...42
  static let idleMicrobehaviorMaxScheduleDelaySeconds: TimeInterval = 60
  static let idleMicrobehaviorMaxPerFiveMinutes = 12

  /// After Orby falls asleep, the mouth stays a flat line for this long before the
  /// slow open-mouth breathing begins.
  static let asleepMouthLineHoldSeconds: TimeInterval = 2.0
  static let idleRareMaxPerThirtyMinutes = 4

  /// Stylized "character beat" cooldown bucket (anime / noir / comet / cat / black hole).
  /// Tuned so they feel like a recurring treat, not a once-an-hour rarity, while staying
  /// well short of attention-seeking: ~one every 7 min minimum, at most 4 per hour, and
  /// never back-to-back.
  static let stylizedMicrobehaviorMinCooldownSeconds: TimeInterval = 7 * 60
  static let stylizedMicrobehaviorMaxPerHour = 4

  static let dizzyStarOrbitPeriodSeconds: TimeInterval = 1.0

  // MARK: - Ambient internal sky events (not microbehaviors)

  static let ambientMeteorInitialDelayRange: ClosedRange<TimeInterval> = 60...120
  static let ambientMeteorIntervalRange: ClosedRange<TimeInterval> = 180...480
  static let ambientMeteorMinimumGap: TimeInterval = 90
  static let ambientMeteorMaxPerTenMinutes = 3
  static let ambientMeteorDurationRange: ClosedRange<TimeInterval> = 0.35...0.9

  static let perseidInitialDelay: TimeInterval = 10 * 60
  static let perseidIntervalRange: ClosedRange<TimeInterval> = (45 * 60)...(90 * 60)
  static let perseidMaxPerSession = 1
  static let perseidAllowedDayNightBlendMax: CGFloat = 0.65
  static let perseidShowerDurationSeconds: TimeInterval = 3.5

  // MARK: - Saturn ring orbit microbehavior

  static let saturnRingOrbitDurationRange: ClosedRange<TimeInterval> = 5.0...7.0
  static let saturnRingOrbitMinCooldownSeconds: TimeInterval = 35 * 60
  static let saturnRingOrbitMaxPerHour = 1
  static let saturnRingOrbitStylizedGapSeconds: TimeInterval = 15 * 60

  static func ambientBlinkInterval(for mood: OrbyMood) -> ClosedRange<TimeInterval> {
    let base: ClosedRange<TimeInterval> =
      switch mood {
      case .neutral, .curious, .pleased, .excited, .thinking:
        3...6.5
      case .focused, .concerned, .skeptical, .overloaded:
        5...10
      case .deepFocus:
        8...15
      case .tired, .sleepy:
        2.5...5.5
      case .passive, .muted:
        6...12
      case .nightWatch:
        7...13
      case .alarmed, .annoyed, .disconnected:
        4...9
      }
    return scaledAmbientBlinkInterval(base)
  }

  private static func scaledAmbientBlinkInterval(_ base: ClosedRange<TimeInterval>) -> ClosedRange<TimeInterval> {
    let m = ambientBlinkIntervalRarityMultiplier
    return (base.lowerBound * m)...(base.upperBound * m)
  }
}

typealias ShrineMiniVisualTiming = OrbyMiniVisualTiming
