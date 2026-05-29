import Foundation
import CoreGraphics

/// Visual phases for Orby (the living face inside Mini Shrine Bubble). Local UI only.
enum OrbyMiniVisualPhase: Equatable {
  case awake
  case hoverExcited
  case dragging
  case postDragDazed(progress: Double)
  case sleepyTransition(progress: Double)
  case asleep
  case wakingQuickBlink(progress: Double)
  case wakingYawn(progress: Double)
  case wakingDoubleBlink(progress: Double)
  case wakingSquint(progress: Double)
  case wakingGlanceRight(progress: Double)
  case wakingGlanceLeft(progress: Double)
  case launchGreeting(progress: Double)
}

/// Coarse phase bucket for mouth settle (ignores sub-phase progress).
enum OrbyMouthPhaseKind: Equatable {
  case awake
  case hoverExcited
  case dragging
  case postDragDazed
  case sleepyTransition
  case asleep
  case waking
  case launchGreeting
}

extension OrbyMiniVisualPhase {
  var mouthPhaseKind: OrbyMouthPhaseKind {
    switch self {
    case .awake: .awake
    case .hoverExcited: .hoverExcited
    case .dragging: .dragging
    case .postDragDazed: .postDragDazed
    case .sleepyTransition: .sleepyTransition
    case .asleep: .asleep
    case .wakingQuickBlink, .wakingYawn, .wakingDoubleBlink, .wakingSquint,
         .wakingGlanceRight, .wakingGlanceLeft:
      .waking
    case .launchGreeting:
      .launchGreeting
    }
  }
}

/// Render-facing snapshot for Orby. Never persisted.
struct OrbyMiniVisualPresentation: Equatable {
  var resolvedMood: OrbyMood
  var intensity: OrbyEmotionIntensity
  var phase: OrbyMiniVisualPhase
  var emotion: OrbyEmotionAppearance

  var cursorEyeOffset: CGSize
  var scriptedEyeOffset: CGSize
  var dragFaceLagOffset: CGSize
  var dragDeformation: OrbyDragDeformationSnapshot
  var dragFaceDeformationStrength: CGFloat
  var headTurnXDegrees: Double
  var headTurnYDegrees: Double

  var eyeTrackingFactor: Double
  var eyelidClosure: Double
  var bezelOnDarkBackground: Bool
  var backgroundLuminance: Double
  var breathingScale: CGFloat
  var zzzOpacity: Double
  var dazedHaloOpacity: Double
  var orbScale: CGFloat
  var isExcited: Bool
  var isDragging: Bool
  var allowsAmbientBlink: Bool
  var ambientBlinkInterval: ClosedRange<TimeInterval>
  var idleMicro: OrbyIdleMicrobehaviorActive?
  var idleMicroOverlay: OrbyIdleMicroOverlay
  var idleFaceNudge: CGSize
  var idleFaceTiltDegrees: Double
  var idleExtraOrbScale: CGFloat
  /// 0…1 — after wake ritual, mouth eases from `closedSlit` into mood mouth.
  var wakeMouthCrossfade: Double = 1
  /// 0…1 — cheek blush overlay (friendly states only).
  var cheekBlushStrength: Double = 0
  /// 0…1 — current point in the slow asleep breathing cycle (0 = exhaled, 1 = inhaled).
  var sleepBreath: Double = 0
  /// 0 = night cosmos, 1 = clear day sky. Driven by local clock (OrbyInnerSkyClock).
  var dayNightBlend: CGFloat = 0

  var mouthParameters: OrbyMouthParameters { emotion.mouth }
  var faceBrightness: Double { emotion.faceBrightness }
}

/// Morphing mouth geometry (one layer; no view swapping).
struct OrbyMouthParameters: Equatable {
  var width: CGFloat = 12
  var lineHeight: CGFloat = 2.5
  var cornerLift: CGFloat = 0
  var curvature: CGFloat = 0.5
  /// 0 = closed bar; 1 = open oval target (`ovalWidth` / `ovalHeight`).
  var openness: CGFloat = 0
  var ovalWidth: CGFloat = 7
  var ovalHeight: CGFloat = 7
  var verticalOffset: CGFloat = 0
}

// MARK: - Legacy Shrine names (surface layer)

typealias ShrineMiniVisualPhase = OrbyMiniVisualPhase
typealias ShrineMiniVisualPresentation = OrbyMiniVisualPresentation
