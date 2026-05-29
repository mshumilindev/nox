import CoreGraphics
import Foundation

/// Sleep depth driver (0 = fully awake, 1 = deeply asleep).
///
/// Ramps up across the falling-asleep transition, holds at 1 while asleep and
/// through the first wake blink, then ramps back to 0 across the yawn so Orby is
/// fully "awake-looking" again right when the yawn finishes. All later wake
/// micro-rituals (double blink, squint, glances) are already fully awake.
enum OrbySleepDepth {
  static func depth(for phase: OrbyMiniVisualPhase) -> CGFloat {
    switch phase {
    case .sleepyTransition(let progress):
      return CGFloat(min(max(progress, 0), 1))
    case .asleep, .wakingQuickBlink:
      return 1
    case .wakingYawn(let progress):
      return CGFloat(1 - min(max(progress, 0), 1))
    case .awake, .hoverExcited, .dragging, .postDragDazed,
         .wakingDoubleBlink, .wakingSquint, .wakingGlanceRight,
         .wakingGlanceLeft, .launchGreeting:
      return 0
    }
  }
}
