import Foundation
import NoxCore

/// Scales how strongly a base mood is rendered (avoids N× duplicate moods).
enum OrbyEmotionIntensity: Equatable, Sendable {
  case subtle
  case normal
  case strong
  case extreme
}

enum OrbyEmotionIntensityResolver {
  static func resolve(mood: OrbyMood, input: ShrineMoodInputs) -> OrbyEmotionIntensity {
    switch mood {
    case .alarmed:
      return input.hasUrgentIntervention ? .strong : .normal
    case .annoyed:
      if input.recentDismissCount >= 5 { return .extreme }
      if input.recentDismissCount >= 4 { return .strong }
      if input.recentDismissCount >= 3 { return .normal }
      return .subtle
    case .concerned:
      if input.overloadSignalCount >= 3 || input.hasSystemContradiction { return .strong }
      return input.overloadSignalCount >= 1 ? .normal : .subtle
    case .overloaded:
      if input.overloadSignalCount >= 5 { return .extreme }
      if input.overloadSignalCount >= 4 { return .strong }
      return .normal
    case .pleased:
      if let focus = input.focusAnalysis, focus.continuityScore >= 0.85 { return .strong }
      return .normal
    case .focused, .deepFocus:
      if let focus = input.focusAnalysis, focus.uninterruptedMs >= 20 * 60 * 1000 { return .strong }
      return .normal
    case .curious, .skeptical, .thinking:
      return .normal
    case .disconnected:
      return input.capabilities.appAwarenessAvailable == false ? .strong : .normal
    default:
      return .normal
    }
  }
}
