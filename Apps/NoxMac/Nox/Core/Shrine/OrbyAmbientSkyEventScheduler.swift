import Foundation

/// Passive internal-sky meteor scheduling — independent of mood and idle microbehaviors.
@MainActor
final class OrbyAmbientSkyEventScheduler {
  private(set) var activeMeteors: [OrbyMeteorEvent] = []

  private var visibleSince: Date?
  private var nextMeteorEligibleAt: Date?
  private var nextPerseidEligibleAt: Date?
  private var lastMeteorAt: Date?
  private var meteorStartsLast10Min: [Date] = []
  private var perseidCountThisSession = 0

  func reset() {
    activeMeteors = []
    visibleSince = nil
    nextMeteorEligibleAt = nil
    nextPerseidEligibleAt = nil
    lastMeteorAt = nil
    meteorStartsLast10Min = []
    perseidCountThisSession = 0
  }

  func noteShow() {
    reset()
    let now = Date()
    visibleSince = now
    nextMeteorEligibleAt = now.addingTimeInterval(
      Double.random(in: OrbyMiniVisualTiming.ambientMeteorInitialDelayRange)
    )
    nextPerseidEligibleAt = now.addingTimeInterval(OrbyMiniVisualTiming.perseidInitialDelay)
  }

  func noteHide() {
    reset()
  }

  func advance(now: Date, context: OrbyAmbientSkySchedulingContext) {
    pruneFinished(now: now)
    guard context.isVisible else { return }

    if !OrbyAmbientSkyEventPolicy.canContinueShowing(context) {
      fadeOutActive(now: now)
      return
    }

    guard OrbyAmbientSkyEventPolicy.canScheduleMeteor(context) else { return }

    if perseidCountThisSession < OrbyMiniVisualTiming.perseidMaxPerSession,
       let nextPerseidEligibleAt,
       now >= nextPerseidEligibleAt,
       OrbyAmbientSkyEventPolicy.canSchedulePerseid(context) {
      triggerPerseid(now: now)
      return
    }

    guard let nextMeteorEligibleAt, now >= nextMeteorEligibleAt else { return }
    guard meteorRateLimitAllows(now: now) else {
      scheduleNextMeteor(after: now, retrySoon: true)
      return
    }
    triggerMeteor(now: now)
  }

  func renderItems(now: Date, context: OrbyAmbientSkySchedulingContext) -> [OrbyAmbientMeteorRenderItem] {
    let multiplier = OrbyAmbientSkyEventPolicy.meteorOpacityMultiplier(
      dayNightBlend: context.dayNightBlend,
      phase: context.phase,
      zzzOpacity: context.zzzOpacity
    )
    let reference = now.timeIntervalSinceReferenceDate
    return activeMeteors.compactMap { meteor in
      renderItem(for: meteor, now: reference, opacityMultiplier: multiplier)
    }
  }

  var hasActiveEvents: Bool { !activeMeteors.isEmpty }

  // MARK: - Private

  private func triggerMeteor(now: Date) {
    let reference = now.timeIntervalSinceReferenceDate
    let meteor = OrbyMeteorPathGenerator.randomMeteor(startedAt: reference)
    activeMeteors.append(meteor)
    lastMeteorAt = now
    meteorStartsLast10Min.append(now)
    scheduleNextMeteor(after: now, retrySoon: false)
  }

  private func triggerPerseid(now: Date) {
    let reference = now.timeIntervalSinceReferenceDate
    let shower = OrbyMeteorPathGenerator.perseidShower(startedAt: reference)
    activeMeteors.append(contentsOf: shower.meteors)
    perseidCountThisSession += 1
    lastMeteorAt = now
    meteorStartsLast10Min.append(now)
    nextPerseidEligibleAt = now.addingTimeInterval(
      Double.random(in: OrbyMiniVisualTiming.perseidIntervalRange)
    )
    scheduleNextMeteor(after: now, retrySoon: false)
  }

  private func scheduleNextMeteor(after now: Date, retrySoon: Bool) {
    let delay = retrySoon
      ? Double.random(in: 45...90)
      : Double.random(in: OrbyMiniVisualTiming.ambientMeteorIntervalRange)
    nextMeteorEligibleAt = now.addingTimeInterval(delay)
  }

  private func meteorRateLimitAllows(now: Date) -> Bool {
    meteorStartsLast10Min.removeAll { now.timeIntervalSince($0) > 600 }
    if meteorStartsLast10Min.count >= OrbyMiniVisualTiming.ambientMeteorMaxPerTenMinutes {
      return false
    }
    if let lastMeteorAt, now.timeIntervalSince(lastMeteorAt) < OrbyMiniVisualTiming.ambientMeteorMinimumGap {
      return false
    }
    return true
  }

  private func pruneFinished(now: Date) {
    let reference = now.timeIntervalSinceReferenceDate
    activeMeteors.removeAll { reference > $0.startedAt + $0.duration + 0.05 }
  }

  private func fadeOutActive(now: Date) {
    let reference = now.timeIntervalSinceReferenceDate
    activeMeteors.removeAll { reference > $0.startedAt + min($0.duration, 0.25) }
  }

  private func renderItem(
    for meteor: OrbyMeteorEvent,
    now: TimeInterval,
    opacityMultiplier: CGFloat
  ) -> OrbyAmbientMeteorRenderItem? {
    let elapsed = now - meteor.startedAt
    guard elapsed >= 0 else { return nil }
    let progress = min(max(elapsed / meteor.duration, 0), 1)
    guard progress < 1 else { return nil }

    let peak = Double(meteor.peakOpacity * opacityMultiplier)
    let headOpacity = peak
      * OrbyMiniVisualEasing.smoothstep(min(max(progress / 0.15, 0), 1))
      * (1 - OrbyMiniVisualEasing.smoothstep(min(max((progress - 0.75) / 0.25, 0), 1)))
    let tailOpacity = peak * 0.7
      * OrbyMiniVisualEasing.smoothstep(min(max((progress - 0.05) / 0.20, 0), 1))
      * (1 - OrbyMiniVisualEasing.smoothstep(min(max((progress - 0.65) / 0.35, 0), 1)))
    guard headOpacity > 0.01 || tailOpacity > 0.01 else { return nil }

    let head = lerp(meteor.start, meteor.end, CGFloat(progress))
    let travel = CGPoint(x: meteor.end.x - meteor.start.x, y: meteor.end.y - meteor.start.y)
    let dir = travel.normalized
    let tailNorm = max(0.001, meteor.tailLength / (OrbyOrbGeometry.orbRadius))
    let tailEnd = CGPoint(
      x: head.x - dir.x * tailNorm,
      y: head.y - dir.y * tailNorm
    )

    return OrbyAmbientMeteorRenderItem(
      head: head,
      tailEnd: tailEnd,
      headSize: meteor.headSize,
      tailWidth: meteor.tailWidth,
      headOpacity: headOpacity,
      tailOpacity: tailOpacity,
      color: meteor.color
    )
  }

  private func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
    CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
  }
}

#if DEBUG
extension OrbyAmbientSkyEventScheduler {
  func debugTriggerMeteor(now: Date = Date()) {
    triggerMeteor(now: now)
  }

  func debugTriggerPerseid(now: Date = Date()) {
    triggerPerseid(now: now)
  }
}
#endif

private extension CGPoint {
  var normalized: CGPoint {
    let len = hypot(x, y)
    guard len > 0.0001 else { return CGPoint(x: 1, y: 0) }
    return CGPoint(x: x / len, y: y / len)
  }
}
