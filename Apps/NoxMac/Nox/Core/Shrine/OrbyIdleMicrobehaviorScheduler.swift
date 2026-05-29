import Foundation

/// Chooses and runs rare idle microbehaviors (never persisted; does not reset sleep timer).
@MainActor
final class OrbyIdleMicrobehaviorScheduler {
  private(set) var active: OrbyIdleMicrobehaviorActive?
  private var startedAt: Date?
  private var nextEligibleAt: Date?
  private var baselineBlinkSuppressUntil: Date?
  private var schedulingSuspended = false

  private var recentStarts: [Date] = []
  private var rareStarts: [Date] = []
  private var particleStarts: [Date] = []
  private var stylizedStarts: [Date] = []
  private var lastMood: OrbyMood = .neutral
  private var lastKind: OrbyIdleMicrobehavior?

  func reset() {
    active = nil
    startedAt = nil
    nextEligibleAt = nil
    baselineBlinkSuppressUntil = nil
    schedulingSuspended = false
    recentStarts = []
    rareStarts = []
    particleStarts = []
    stylizedStarts = []
    lastKind = nil
  }

  func noteShow() {
    reset()
    let delay = Double.random(in: OrbyMiniVisualTiming.idleMicrobehaviorInitialDelayRange)
    nextEligibleAt = Date().addingTimeInterval(delay)
  }

  func noteManualShowcase() {
    reset()
    let delay = Double.random(in: OrbyMiniVisualTiming.idleMicrobehaviorInitialDelayRange)
    nextEligibleAt = Date().addingTimeInterval(delay)
  }

  /// Freezes the schedule timer (keeps `nextEligibleAt`). Does **not** apply post-interrupt cooldown.
  func setSchedulingSuspended(_ suspended: Bool) {
    if suspended {
      guard !schedulingSuspended else { return }
      schedulingSuspended = true
      if active != nil {
        active = nil
        startedAt = nil
      }
      return
    }
    schedulingSuspended = false
  }

  var isSchedulingSuspended: Bool { schedulingSuspended }

  func advance(now: Date, mood: OrbyMood) {
    lastMood = mood
    guard !schedulingSuspended else { return }
    guard let active, let startedAt else { return }
    let p = min(max(now.timeIntervalSince(startedAt) / active.duration, 0), 1)
    self.active?.progress = p
    if p >= 1 {
      finish(now: now, mood: lastMood)
    }
  }

  func trySchedule(now: Date, context: OrbyIdleMicroContext, mood: OrbyMood) {
    lastMood = mood
    guard !schedulingSuspended else { return }
    guard active == nil else { return }
    pruneHistory(now: now)
    guard OrbyIdleMicrobehaviorPolicy.canSchedule(context) else { return }
    if let nextEligibleAt, now < nextEligibleAt { return }
    if !rateLimitAllows(now: now) { return }

    // When the stylized bucket isn't open yet, remove all stylized beats from the draw.
    var disallow: Set<OrbyIdleMicrobehavior> = []
    if !stylizedAllowed(now: now) {
      for behavior in OrbyIdleMicrobehavior.allCases where behavior.isStylized {
        disallow.insert(behavior)
      }
    }

    guard let kind = OrbyIdleMicrobehaviorWeights.pickRandom(
      context: context,
      excluding: lastKind,
      disallow: disallow
    ) else {
      scheduleRetrySoon(mood: mood)
      return
    }

    let range = kind.durationSeconds()
    let duration = Double.random(in: range)
    active = OrbyIdleMicrobehaviorActive(kind: kind, progress: 0, duration: duration)
    lastKind = kind
    startedAt = now
    recentStarts.append(now)
    if kind == .tonguePeek || kind == .bubbleBlow || kind == .tinySneeze || kind == .pixelShiver {
      rareStarts.append(now)
    }
    if kind.usesParticles { particleStarts.append(now) }
    if kind.isStylized { stylizedStarts.append(now) }
    baselineBlinkSuppressUntil = nil
  }

  /// Stylized cooldown bucket: never back-to-back, at least `MinCooldown` since the last
  /// stylized beat, and no more than `MaxPerHour`.
  private func stylizedAllowed(now: Date) -> Bool {
    if let lastKind, lastKind.isStylized { return false }
    if let last = stylizedStarts.last,
       now.timeIntervalSince(last) < OrbyMiniVisualTiming.stylizedMicrobehaviorMinCooldownSeconds {
      return false
    }
    let inLastHour = stylizedStarts.filter { now.timeIntervalSince($0) < 3600 }.count
    return inLastHour < OrbyMiniVisualTiming.stylizedMicrobehaviorMaxPerHour
  }

  func currentFrame(baseMouth: OrbyMouthParameters) -> OrbyIdleMicrobehaviorFrame? {
    guard let active else { return nil }
    return OrbyIdleMicrobehaviorAnimation.frame(
      for: active.kind,
      progress: active.progress,
      baseMouth: baseMouth
    )
  }

  func cancelActiveForInteraction(now: Date, mood: OrbyMood) {
    guard active != nil else { return }
    active = nil
    startedAt = nil
    baselineBlinkSuppressUntil = now.addingTimeInterval(0.8)
    scheduleCooldown(mood: mood)
  }

  func allowsBaselineBlink(now: Date) -> Bool {
    if active != nil { return false }
    if let until = baselineBlinkSuppressUntil, now < until { return false }
    return true
  }

  private func finish(now: Date, mood: OrbyMood) {
    active = nil
    startedAt = nil
    let pause = Double.random(in: OrbyMiniVisualTiming.postIdleBlinkDelayRange)
    baselineBlinkSuppressUntil = now.addingTimeInterval(pause)
    scheduleCooldown(mood: mood)
  }

  private func scheduleCooldown(mood: OrbyMood) {
    let delay = scaledDelay(
      in: OrbyMiniVisualTiming.idleMicrobehaviorCooldownRange,
      mood: mood
    )
    nextEligibleAt = Date().addingTimeInterval(delay)
  }

  private func scheduleRetrySoon(mood: OrbyMood) {
    let scale = max(OrbyIdleMicrobehaviorPolicy.scheduleMultiplier(mood: mood), 0.2)
    let delay = Double.random(in: 10...18) / scale
    nextEligibleAt = Date().addingTimeInterval(delay)
  }

  private func scaledDelay(in range: ClosedRange<TimeInterval>, mood: OrbyMood) -> TimeInterval {
    let scale = max(OrbyIdleMicrobehaviorPolicy.scheduleMultiplier(mood: mood), 0.2)
    let base = Double.random(in: range)
    return min(base / scale, OrbyMiniVisualTiming.idleMicrobehaviorMaxScheduleDelaySeconds)
  }

  private func rateLimitAllows(now: Date) -> Bool {
    if recentStarts.filter({ now.timeIntervalSince($0) < 300 }).count
      >= OrbyMiniVisualTiming.idleMicrobehaviorMaxPerFiveMinutes { return false }
    if rareStarts.filter({ now.timeIntervalSince($0) < 1800 }).count
      >= OrbyMiniVisualTiming.idleRareMaxPerThirtyMinutes { return false }
    if particleStarts.filter({ now.timeIntervalSince($0) < 240 }).count >= 4 { return false }
    return true
  }

  private func pruneHistory(now: Date) {
    recentStarts.removeAll { now.timeIntervalSince($0) > 300 }
    rareStarts.removeAll { now.timeIntervalSince($0) > 1800 }
    particleStarts.removeAll { now.timeIntervalSince($0) > 240 }
    stylizedStarts.removeAll { now.timeIntervalSince($0) > 3600 }
  }
}

#if DEBUG
extension OrbyIdleMicrobehaviorScheduler {
  var nextEligibleAtForTesting: Date? { nextEligibleAt }
}
#endif
