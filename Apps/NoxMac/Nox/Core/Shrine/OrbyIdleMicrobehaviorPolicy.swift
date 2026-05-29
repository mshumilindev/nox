import Foundation

enum OrbyIdleMicrobehaviorPolicy {
  /// Drag, hover, dizzy, sleep/wake ritual, and context menu freeze the micro timer (pause, not restart).
  static func schedulingSuspended(
    for phase: OrbyMiniVisualPhase,
    isContextMenuOpen: Bool
  ) -> Bool {
    if isContextMenuOpen { return true }
    switch phase {
    case .hoverExcited, .dragging, .postDragDazed, .sleepyTransition, .asleep, .launchGreeting,
         .wakingQuickBlink, .wakingYawn, .wakingDoubleBlink, .wakingSquint,
         .wakingGlanceRight, .wakingGlanceLeft:
      return true
    default:
      return false
    }
  }

  static func canSchedule(_ context: OrbyIdleMicroContext) -> Bool {
    guard context.isVisible else { return false }
    guard isSchedulablePhase(context.phase) else { return false }
    guard !context.isDragging, !context.isContextMenuOpen else { return false }
    guard context.secondsUntilSleepThreshold > 4 else { return false }
    return true
  }

  static func canRun(_ behavior: OrbyIdleMicrobehavior, context: OrbyIdleMicroContext) -> Bool {
    guard canSchedule(context) else { return false }
    if context.isHovering || context.cursorInsideOrb { return behavior.isSubtleWhileHovering }
    if context.secondsUntilSleepThreshold < 8 {
      return behavior == .humPulse || behavior == .pixelShiver || behavior == .microSmile
    }
    return true
  }

  /// Higher → more frequent scheduling (not longer delays). Timing only — does not filter which behavior runs.
  static func scheduleMultiplier(mood: OrbyMood) -> Double {
    switch mood {
    case .deepFocus:
      return 0.2
    case .focused:
      return 0.55
    case .passive, .muted, .nightWatch:
      return 0.35
    case .tired, .sleepy:
      return 0.4
    default:
      return 1
    }
  }

  private static func isSchedulablePhase(_ phase: OrbyMiniVisualPhase) -> Bool {
    switch phase {
    case .awake:
      true
    default:
      false
    }
  }
}
