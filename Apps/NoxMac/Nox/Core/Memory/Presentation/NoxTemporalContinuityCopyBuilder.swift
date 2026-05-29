import Foundation
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore
import NoxShrineCore

nonisolated enum NoxTemporalContinuityCopyBuilder {

  private static let confidenceFloor = 0.42

  static func temporalStamp(
    lastActiveAt: Date,
    state: NoxMemoryTemporalState,
    confidence: Double,
    recurrenceStrength: Double,
    period: NoxMemoryPeriod = .today,
    at: Date = Date()
  ) -> String? {
    guard confidence >= confidenceFloor else { return nil }
    let gap = at.timeIntervalSince(lastActiveAt)

    switch state {
    case .active:
      if period == .lastSevenDays {
        if gap < 90 * 60 { return "recently active" }
        if gap < 2 * 86_400 { return "active this week" }
        return "active earlier in the period"
      }
      if gap < 90 * 60 { return "recently active" }
      if gap < 8 * 3600 { return "active earlier today" }
      return "appeared repeatedly today"
    case .fading:
      if gap < 36 * 3600 { return "fading from recent activity" }
      if gap < 5 * 86_400 { return "quiet for a few days" }
      return "quiet for several days"
    case .dormant:
      if gap < 14 * 86_400 { return "quiet for several days" }
      return "distant in recent memory"
    case .archival:
      return "distant in recent memory"
    case .resurfacing:
      if gap >= 72 * 3600 { return "returned this week" }
      if period == .today, recurrenceStrength >= 0.45 { return "kept returning today" }
      if period == .lastSevenDays { return "returned this week" }
      return "resurfaced after a gap"
    }
  }

  static func continuityDetail(
    thread: NoxContinuityThread,
    state: NoxMemoryTemporalState,
    unresolved: NoxUnresolvedContinuitySignal?,
    period: NoxMemoryPeriod = .today,
    at: Date = Date()
  ) -> String? {
    guard thread.sensitivityLevel == .normal else {
      return "Generalized activity only"
    }
    guard thread.confidence >= confidenceFloor else { return nil }

    if let unresolved, unresolved.persistenceScore >= 0.55 {
      return unresolvedDetail(thread: thread, signal: unresolved, period: period, at: at)
    }

    let gap = at.timeIntervalSince(thread.lastSeenAt)
    let sameDay = sameDayContext(period: period, gap: gap)

    if thread.totalResumptions >= 4, sameDay {
      return "interrupted repeatedly today"
    }
    if thread.totalResumptions >= 2 {
      if thread.recurrenceStrength >= 0.45 {
        return "returned across several sessions"
      }
      return "returned after interruptions"
    }
    if thread.recurrenceStrength >= 0.5 {
      return "still open across recent sessions"
    }
    if state == .resurfacing {
      return "returned after interruptions"
    }
    if thread.totalSessions > 1, sameDay {
      return "kept resurfacing during work"
    }
    if state == .fading || state == .dormant {
      return recurrenceHint(thread, state: state)
    }
    if thread.totalSessions > 1 {
      return "still forming"
    }
    return nil
  }

  static func unresolvedDetail(
    thread: NoxContinuityThread,
    signal: NoxUnresolvedContinuitySignal?,
    period: NoxMemoryPeriod = .today,
    at: Date = Date()
  ) -> String {
    if let signal, signal.persistenceScore >= 0.62, !signal.detail.isEmpty {
      return NoxEmotionalSafetyCopy.sanitize(signal.detail)
    }
    let gap = at.timeIntervalSince(thread.lastSeenAt)
    if thread.totalResumptions >= 3, sameDayContext(period: period, gap: gap) {
      return "interrupted repeatedly today"
    }
    if thread.totalResumptions >= 2 {
      return "returned across several sessions"
    }
    return "still open across recent continuity"
  }

  static func arcDetail(
    arc: NoxSemanticArc,
    state: NoxMemoryTemporalState,
    thread: NoxContinuityThread?
  ) -> String? {
    guard arc.strength >= confidenceFloor else { return nil }
    if state == .resurfacing {
      return "resurfaced after a gap"
    }
    if let thread, thread.totalResumptions >= 2 {
      return "returned across several sessions"
    }
    if arc.continuityState == .resurfaced {
      return "reappeared during recent focus"
    }
    return arc.detailLine
  }

  static func arcEvolutionLine(arc: NoxSemanticArc, state: NoxMemoryTemporalState) -> String {
    switch state {
    case .archival, .dormant:
      return "older \(arc.label.lowercased()) activity"
    case .resurfacing:
      return "\(arc.label) activity returned"
    case .fading:
      return "\(arc.label) activity is fading"
    default:
      if arc.evolution == .strengthening {
        return "\(arc.spanCount) spans · increasing"
      }
      return "\(arc.spanCount) spans · \(arcEvolutionLabel(arc.evolution))"
    }
  }

  static func longTermResurfacingTitle(
    thread: NoxContinuityThread?,
    arc: NoxSemanticArc?
  ) -> String {
    if let thread, thread.sensitivityLevel == .normal {
      let name = thread.title.replacingOccurrences(of: " continuity", with: "")
      return "Returning \(name.lowercased()) activity"
    }
    if let arc {
      return "Older \(arc.label.lowercased()) activity returned"
    }
    return "Returning activity"
  }

  static func longTermResurfacingSubtitle(
    thread: NoxContinuityThread?,
    arc: NoxSemanticArc?,
    at: Date = Date()
  ) -> String {
    if let thread {
      let gap = at.timeIntervalSince(thread.lastSeenAt)
      if gap >= 14 * 86_400 { return "briefly returned after a long gap" }
      if gap >= 72 * 3600 { return "quiet for several days" }
      return "reappeared during recent focus"
    }
    if let arc {
      if arc.continuityState == .resurfaced { return "reappeared during recent focus" }
      return "quiet for several days"
    }
    return "quiet for several days"
  }

  static func eraObservation(for hint: NoxEraEvolutionHint) -> String {
    let label = hint.softLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !label.isEmpty else {
      return "A recurring activity pattern still appears in recent days."
    }
    if hint.overlapping {
      return "\(label) still appears across recent days."
    }
    if hint.resonance >= 0.55 {
      return "A quieter \(label.lowercased()) pattern has recently returned."
    }
    return "\(label) activity is fading from recent days."
  }

  private static func sameDayContext(period: NoxMemoryPeriod, gap: TimeInterval) -> Bool {
    switch period {
    case .today:
      return gap < 20 * 3600
    case .yesterday:
      return gap < 36 * 3600
    case .lastSevenDays:
      return false
    }
  }

  private static func recurrenceHint(
    _ thread: NoxContinuityThread,
    state: NoxMemoryTemporalState
  ) -> String {
    if thread.recurrenceStrength >= 0.5 {
      return "recurring across recent days"
    }
    if state == .fading {
      return "fading from recent activity"
    }
    return "recurring across recent days"
  }

  private static func arcEvolutionLabel(_ evolution: NoxArcEvolution) -> String {
    switch evolution {
    case .strengthening: return "increasing"
    case .stable: return "stable"
    case .fragmenting: return "fragmenting"
    case .decaying: return "declining"
    }
  }
}
