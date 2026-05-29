import Foundation

/// When Orby shows cheek blush (`cheekBlushStrength` > 0).
enum OrbyCheekBlushPolicy {
  static func resolvedStrength(
    phase: OrbyMiniVisualPhase,
    compositorStrength: Double,
    idleMicro: OrbyIdleMicrobehavior?
  ) -> Double {
    guard !isSuppressed(phase: phase) else { return 0 }
    var strength = min(max(compositorStrength, 0), 1)
    if let idleMicro {
      switch idleMicro {
      case .microSmile:
        strength = max(strength, 0.65)
      case .tonguePeek:
        strength = max(strength, 0.55)
      case .animeSelfSatisfied:
        strength = max(strength, 0.5)
      case .catMode:
        strength = max(strength, 0.35)
      default:
        break
      }
    }
    return min(max(strength, 0), 1)
  }

  static func isSuppressed(phase: OrbyMiniVisualPhase) -> Bool {
    switch phase {
    case .dragging, .postDragDazed, .asleep, .sleepyTransition,
         .wakingQuickBlink, .wakingYawn, .wakingDoubleBlink, .wakingSquint,
         .wakingGlanceRight, .wakingGlanceLeft:
      return true
    case .awake, .hoverExcited, .launchGreeting:
      return false
    }
  }
}
