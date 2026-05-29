import Foundation

struct OrbyAmbientSkySchedulingContext: Equatable {
  var phase: OrbyMiniVisualPhase
  var mood: OrbyMood
  var isVisible: Bool
  var isDragging: Bool
  var isContextMenuOpen: Bool
  var dayNightBlend: CGFloat
  var zzzOpacity: Double
  var activeMicrobehavior: OrbyIdleMicrobehavior?
}

enum OrbyAmbientSkyEventPolicy {
  static func canScheduleMeteor(_ context: OrbyAmbientSkySchedulingContext) -> Bool {
    guard context.isVisible else { return false }
    guard !context.isDragging, !context.isContextMenuOpen else { return false }
    guard !isBusyPhase(context.phase) else { return false }
    guard !isBusyMicrobehavior(context.activeMicrobehavior) else { return false }
    if context.zzzOpacity > 0.55 { return false }
    return true
  }

  static func canSchedulePerseid(_ context: OrbyAmbientSkySchedulingContext) -> Bool {
    guard canScheduleMeteor(context) else { return false }
    guard context.dayNightBlend < OrbyMiniVisualTiming.perseidAllowedDayNightBlendMax else { return false }
    if case .hoverExcited = context.phase { return false }
    if case .asleep = context.phase { return context.dayNightBlend < 0.35 }
    return true
  }

  static func canContinueShowing(_ context: OrbyAmbientSkySchedulingContext) -> Bool {
    guard context.isVisible else { return false }
    if context.isDragging || context.isContextMenuOpen { return false }
    if isHardSuppressPhase(context.phase) { return false }
    if isBusyMicrobehavior(context.activeMicrobehavior) { return false }
    return true
  }

  static func meteorOpacityMultiplier(
    dayNightBlend: CGFloat,
    phase: OrbyMiniVisualPhase,
    zzzOpacity: Double
  ) -> CGFloat {
    let blend = min(max(dayNightBlend, 0), 1)
    var multiplier = CGFloat(1.0 + (0.30 - 1.0) * blend)
    if case .asleep = phase {
      multiplier *= 0.62
    }
    if zzzOpacity > 0.25 {
      multiplier *= CGFloat(1.0 - min(zzzOpacity, 1) * 0.35)
    }
    switch phase {
    case .hoverExcited:
      multiplier *= 0.85
    default:
      break
    }
    switch phase {
    case .awake:
      break
    default:
      if case .asleep = phase { break } else { multiplier *= 0.9 }
    }
    return max(0.08, multiplier)
  }

  private static func isHardSuppressPhase(_ phase: OrbyMiniVisualPhase) -> Bool {
    switch phase {
    case .dragging, .postDragDazed, .launchGreeting,
         .wakingQuickBlink, .wakingYawn, .wakingDoubleBlink, .wakingSquint,
         .wakingGlanceRight, .wakingGlanceLeft:
      return true
    default:
      return false
    }
  }

  private static func isBusyPhase(_ phase: OrbyMiniVisualPhase) -> Bool {
    if isHardSuppressPhase(phase) { return true }
    if case .sleepyTransition = phase { return true }
    if case .hoverExcited = phase { return true }
    return false
  }

  private static func isBusyMicrobehavior(_ behavior: OrbyIdleMicrobehavior?) -> Bool {
    guard let behavior else { return false }
    switch behavior {
    case .animeSelfSatisfied, .noirDetective, .cosmicCometWatch, .catMode, .blackHoleNibble,
         .saturnRingOrbit:
      return true
    default:
      return false
    }
  }
}
