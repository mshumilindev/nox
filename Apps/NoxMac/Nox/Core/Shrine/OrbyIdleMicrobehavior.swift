import CoreGraphics
import Foundation

/// Rare awake idle actions — not baseline blink, not persisted.
enum OrbyIdleMicrobehavior: String, CaseIterable, Equatable {
  case microSmile
  case eyeWander
  case glanceAround
  case humPulse
  case selfPolish
  case tonguePeek
  case bubbleBlow
  case cheekPuff
  case tinyYawn
  case sleepyNod
  case sparkleCatch
  case sideEye
  case tinySneeze
  case pixelShiver
  case animeSelfSatisfied
  case noirDetective
  case cosmicCometWatch
  case catMode
  case blackHoleNibble

  /// Rare, visually rich "character beat" behaviors. Share one cooldown bucket
  /// (min gap + max-per-hour) and a mood gate; never back-to-back.
  var isStylized: Bool {
    switch self {
    case .animeSelfSatisfied, .noirDetective, .cosmicCometWatch, .catMode, .blackHoleNibble:
      return true
    default:
      return false
    }
  }

  var isPlayful: Bool {
    switch self {
    case .tonguePeek, .bubbleBlow, .cheekPuff, .tinySneeze, .pixelShiver:
      true
    default:
      false
    }
  }

  var usesParticles: Bool {
    switch self {
    case .selfPolish, .sparkleCatch, .bubbleBlow, .tinySneeze:
      true
    default:
      false
    }
  }

  /// Allowed when the cursor rests on the orb (`hoverExcited`); playful overlays stay off.
  var isSubtleWhileHovering: Bool {
    switch self {
    case .tonguePeek, .bubbleBlow, .cheekPuff, .tinySneeze, .pixelShiver, .sparkleCatch, .selfPolish,
         .animeSelfSatisfied, .noirDetective, .cosmicCometWatch, .catMode, .blackHoleNibble:
      false
    default:
      true
    }
  }

  func durationSeconds() -> ClosedRange<TimeInterval> {
    switch self {
    case .microSmile: 1.8...2.8
    case .eyeWander: 2.2...3.2
    case .glanceAround: 1.8...2.7
    case .humPulse: 2.4...3.6
    case .selfPolish: 1.9...2.8
    case .tonguePeek: 2.2...3.2
    case .bubbleBlow: 3.0...4.2
    case .cheekPuff: 1.5...2.3
    case .tinyYawn: 1.8...2.6
    case .sleepyNod: 1.8...2.7
    case .sparkleCatch: 1.9...3.0
    case .sideEye: 1.5...2.2
    case .tinySneeze: 0.9...1.4
    case .pixelShiver: 0.55...0.9
    case .animeSelfSatisfied: 2.6...3.4
    case .noirDetective: 5.0...6.0
    case .cosmicCometWatch: 4.5...5.5
    case .catMode: 3.0...4.0
    case .blackHoleNibble: 5.5...6.5
    }
  }
}

/// Transient overlay channels (not a second mouth).
struct OrbyIdleMicroOverlay: Equatable {
  var tongueProgress: Double = 0
  var bubbleCenter: CGPoint?
  var bubbleRadius: CGFloat = 0
  var bubbleOpacity: Double = 0
  var sparkleOpacity: Double = 0
  var sparklePoint: CGPoint = .zero
  var rimGlintOpacity: Double = 0
  var rimGlintProgress: Double = 0
  var faceJitter: CGSize = .zero
  var puffScale: CGFloat = 1
  /// 0…1 — anime self-satisfied eye reveal (drawn sparkle eyes morph in/out).
  var animeEyeReveal: Double = 0
  /// 0…1 — anime self-satisfied tiny glint sparkles opacity.
  var animeSparkleOpacity: Double = 0

  // MARK: Stylized "character beat" overlays (clipped inside the orb unless noted)

  /// 0…1 — noir grading + diagonal venetian light-band strength.
  var noirReveal: Double = 0
  /// Slowly advancing phase (radians) for the noir light-band sweep.
  var noirBandPhase: Double = 0
  /// 0…1 — optional tiny "clue" glint near the lower interior during noir search.
  var noirClueOpacity: Double = 0
  /// 0…1 — cat-mode stylized slit-eye reveal (drawn cat eyes morph in/out).
  var catEyeReveal: Double = 0
  /// 0…1 — comet event opacity (0 = no comet).
  var cometOpacity: Double = 0
  /// 0…1 — comet position along its entry→exit path (crosses the orb boundary).
  var cometProgress: Double = 0
  /// 0…1 — black-hole presence (core + accretion ring) strength.
  var blackHoleStrength: Double = 0
  /// -1 = black hole on left, +1 = on right. Face shifts the opposite way.
  var blackHoleSide: CGFloat = 1
  /// 0…1 — progress of the nibbled star being pulled into the black hole.
  var blackHoleStarProgress: Double = 0
}

/// Per-frame idle output merged into presentation (local UI only).
struct OrbyIdleMicrobehaviorFrame: Equatable {
  var scriptedEyeOffset: CGSize = .zero
  var eyelidClosure: Double?
  var mouth: OrbyMouthParameters?
  var leftEyeHeightScale: CGFloat = 1
  var rightEyeHeightScale: CGFloat = 1
  var faceNudge: CGSize = .zero
  var extraOrbScale: CGFloat = 1
  var extraWarmth: Double = 0
  var trackingFactor: Double?
  var headTurnYExtra: Double = 0
  var headTurnXExtra: Double = 0
  var faceTiltDegrees: Double = 0
  var overlay: OrbyIdleMicroOverlay = OrbyIdleMicroOverlay()
}

struct OrbyIdleMicrobehaviorActive: Equatable {
  var kind: OrbyIdleMicrobehavior
  var progress: Double
  var duration: TimeInterval
}

struct OrbyIdleMicroContext: Equatable {
  var mood: OrbyMood
  var phase: OrbyMiniVisualPhase
  var isVisible: Bool
  var isHovering: Bool
  var isDragging: Bool
  var isContextMenuOpen: Bool
  var cursorInsideOrb: Bool
  /// Seconds until cursor-idle sleep threshold (30s). Used to skip micro near sleep.
  var secondsUntilSleepThreshold: TimeInterval
}
