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

nonisolated enum NoxTemporalMemoryRowPresenter {

  static func enrich(
    sections: [NoxTimelineSection],
    threads: [NoxContinuityThread],
    arcs: [NoxSemanticArc],
    evolution: NoxMemoryEvolutionSnapshot,
    ecologyCoupling: [String: Double] = [:],
    period: NoxMemoryPeriod = .today,
    at: Date = Date()
  ) -> [NoxTimelineSection] {
    let profileMap = Dictionary(uniqueKeysWithValues: evolution.agingProfiles.map { ($0.subjectId, $0) })
    let unresolvedMap = Dictionary(uniqueKeysWithValues: evolution.unresolvedSignals.map { ($0.subjectId, $0) })
    let weightMap = evolution.temporalWeights

    var enriched = sections.map { section in
      let items = section.items.map {
        enrichItem(
          $0,
          profileMap: profileMap,
          unresolvedMap: unresolvedMap,
          weightMap: weightMap,
          threads: threads,
          arcs: arcs,
          evolution: evolution,
          ecologyCoupling: ecologyCoupling,
          period: period,
          at: at
        )
      }
      return NoxTimelineSection(layer: section.layer, items: items)
    }

    if let resurfacing = buildResurfacingItems(
      threads: threads,
      arcs: arcs,
      evolution: evolution,
      profileMap: profileMap,
      period: period,
      at: at
    ), !resurfacing.isEmpty {
      enriched = injectResurfacing(resurfacing, into: enriched)
    }

    return enriched
  }

  static func eraObservation(for evolution: NoxMemoryEvolutionSnapshot) -> String? {
    guard !evolution.preferSparseSurfaces else { return nil }
    guard let hint = evolution.eraHints.first, hint.resonance >= 0.38 else { return nil }
    return NoxTemporalContinuityCopyBuilder.eraObservation(for: hint)
  }

  static func presentation(
    for thread: NoxContinuityThread,
    evolution: NoxMemoryEvolutionSnapshot,
    at: Date = Date()
  ) -> NoxTimelineRowPresentation {
    let profile = evolution.agingProfiles.first { $0.subjectId == thread.id }
    let input = agingInput(thread: thread, weight: evolution.temporalWeights[thread.id], at: at)
    var base = NoxMemoryAgingPresenter.presentation(profile: profile, input: input)
    let relation = NoxMemoryRelationPresenter.relationLine(
      subjectId: thread.id,
      semanticType: thread.semanticType,
      threads: [],
      arcs: [],
      ecologyCoupling: [:],
      ecologyNotes: evolution.ecologyNotes,
      at: at
    )
    if let relation {
      return NoxTimelineRowPresentation(
        temporalState: base.temporalState,
        titleOpacity: base.titleOpacity,
        metadataOpacity: base.metadataOpacity,
        detailOpacity: base.detailOpacity,
        iconOpacity: base.iconOpacity,
        suppressDuration: base.suppressDuration,
        relationLine: relation
      )
    }
    return base
  }

  static func continuityCardDetail(
    thread: NoxContinuityThread,
    evolution: NoxMemoryEvolutionSnapshot,
    at: Date = Date()
  ) -> String {
    let profile = evolution.agingProfiles.first { $0.subjectId == thread.id }
    let state = NoxMemoryAgingPresenter.temporalState(
      profile: profile,
      input: agingInput(thread: thread, weight: evolution.temporalWeights[thread.id], at: at)
    )
    let unresolved = evolution.unresolvedSignals.first { $0.subjectId == thread.id }
    return NoxTemporalContinuityCopyBuilder.continuityDetail(
      thread: thread,
      state: state,
      unresolved: unresolved,
      period: .today,
      at: at
    ) ?? NoxContinuityResurfacingPresenter.threadDetailLine(thread)
  }

  static func continuityCardStamp(
    thread: NoxContinuityThread,
    evolution: NoxMemoryEvolutionSnapshot,
    at: Date = Date()
  ) -> String? {
    let profile = evolution.agingProfiles.first { $0.subjectId == thread.id }
    let input = agingInput(thread: thread, weight: evolution.temporalWeights[thread.id], at: at)
    let state = NoxMemoryAgingPresenter.temporalState(profile: profile, input: input)
    return NoxTemporalContinuityCopyBuilder.temporalStamp(
      lastActiveAt: thread.lastSeenAt,
      state: state,
      confidence: thread.confidence,
      recurrenceStrength: thread.recurrenceStrength,
      period: .today,
      at: at
    )
  }

  // MARK: - Private

  private static func enrichItem(
    _ item: NoxTimelineBlockItem,
    profileMap: [String: NoxMemoryAgingProfile],
    unresolvedMap: [String: NoxUnresolvedContinuitySignal],
    weightMap: [String: Double],
    threads: [NoxContinuityThread],
    arcs: [NoxSemanticArc],
    evolution: NoxMemoryEvolutionSnapshot,
    ecologyCoupling: [String: Double],
    period: NoxMemoryPeriod,
    at: Date
  ) -> NoxTimelineBlockItem {
    switch item.kind {
    case .continuityThread(let thread):
      return enrichContinuity(
        item,
        thread: thread,
        profile: profileMap[thread.id],
        unresolved: unresolvedMap[thread.id],
        weight: weightMap[thread.id],
        threads: threads,
        arcs: arcs,
        evolution: evolution,
        ecologyCoupling: ecologyCoupling,
        period: period,
        at: at
      )
    case .semanticSpan(let span):
      return enrichSemantic(
        item,
        span: span,
        profile: profileMap[span.id],
        period: period,
        at: at
      )
      case .activitySpan(let span):
      return enrichActivity(item, span: span)
    default:
      return item
    }
  }

  private static func enrichContinuity(
    _ item: NoxTimelineBlockItem,
    thread: NoxContinuityThread,
    profile: NoxMemoryAgingProfile?,
    unresolved: NoxUnresolvedContinuitySignal?,
    weight: Double?,
    threads: [NoxContinuityThread],
    arcs: [NoxSemanticArc],
    evolution: NoxMemoryEvolutionSnapshot,
    ecologyCoupling: [String: Double],
    period: NoxMemoryPeriod,
    at: Date
  ) -> NoxTimelineBlockItem {
    let input = agingInput(thread: thread, weight: weight, at: at)
    var presentation = NoxMemoryAgingPresenter.presentation(profile: profile, input: input)
    let state = presentation.temporalState

    let detail = NoxTemporalContinuityCopyBuilder.continuityDetail(
      thread: thread,
      state: state,
      unresolved: unresolved,
      period: period,
      at: at
    )
    let stamp = NoxTemporalContinuityCopyBuilder.temporalStamp(
      lastActiveAt: thread.lastSeenAt,
      state: state,
      confidence: thread.confidence,
      recurrenceStrength: thread.recurrenceStrength,
      period: period,
      at: at
    )
    let relation = period == .today
      ? NoxMemoryRelationPresenter.relationLine(
          subjectId: thread.id,
          semanticType: thread.semanticType,
          threads: threads,
          arcs: arcs,
          ecologyCoupling: ecologyCoupling,
          ecologyNotes: evolution.ecologyNotes,
          at: at
        )
      : nil
    if let relation {
      presentation = NoxTimelineRowPresentation(
        temporalState: presentation.temporalState,
        titleOpacity: presentation.titleOpacity,
        metadataOpacity: presentation.metadataOpacity,
        detailOpacity: presentation.detailOpacity,
        iconOpacity: presentation.iconOpacity,
        suppressDuration: presentation.suppressDuration,
        relationLine: relation
      )
    }

    let duration = stableDurationText(
      suppressDuration: presentation.suppressDuration,
      temporalStamp: stamp,
      fallback: item.durationText
    )
    let resolvedDetail = detail ?? item.detailLine
    return NoxTimelineBlockItem(
      id: item.id,
      timestamp: item.timestamp,
      kind: item.kind,
      title: item.title,
      subtitle: item.subtitle,
      detailLine: resolvedDetail,
      durationText: duration,
      category: item.category,
      markerSymbol: item.markerSymbol,
      presentation: presentation,
      isLongTermResurfacing: false
    )
  }

  private static func enrichSemantic(
    _ item: NoxTimelineBlockItem,
    span: NoxSemanticMemorySpan,
    profile: NoxMemoryAgingProfile?,
    period: NoxMemoryPeriod,
    at: Date
  ) -> NoxTimelineBlockItem {
    let lastActive = span.endedAt ?? span.startedAt
    let input = NoxMemoryAgingPresenter.Input(
      subjectId: span.id,
      lastActiveAt: lastActive,
      recurrenceStrength: 0.35,
      continuityGravity: 0.45,
      temporalWeight: nil,
      confidence: 0.55,
      isResumed: span.endedAt == nil,
      at: at
    )
    let presentation = NoxMemoryAgingPresenter.presentation(profile: profile, input: input)
    let stamp = NoxTemporalContinuityCopyBuilder.temporalStamp(
      lastActiveAt: lastActive,
      state: presentation.temporalState,
      confidence: input.confidence,
      recurrenceStrength: input.recurrenceStrength,
      period: period,
      at: at
    )
    let useTemporalStamp = span.endedAt != nil
      && at.timeIntervalSince(lastActive) > 2 * 3600
    let detailLine: String?
    if span.endedAt == nil {
      detailLine = "still forming"
    } else {
      detailLine = item.detailLine
    }
    return NoxTimelineBlockItem(
      id: item.id,
      timestamp: item.timestamp,
      kind: item.kind,
      title: item.title,
      subtitle: item.subtitle,
      detailLine: detailLine,
      durationText: stableDurationText(
        suppressDuration: useTemporalStamp,
        temporalStamp: stamp,
        fallback: item.durationText
      ),
      category: item.category,
      markerSymbol: item.markerSymbol,
      presentation: presentation,
      isLongTermResurfacing: false
    )
  }

  private static func enrichActivity(
    _ item: NoxTimelineBlockItem,
    span: NoxActivitySpan
  ) -> NoxTimelineBlockItem {
    let minutes = span.durationMs / 60_000
    if minutes <= 2 {
      return NoxTimelineBlockItem(
        id: item.id,
        timestamp: item.timestamp,
        kind: item.kind,
        title: item.title,
        subtitle: item.subtitle,
        detailLine: item.detailLine,
        durationText: nil,
        category: item.category,
        markerSymbol: item.markerSymbol,
        presentation: NoxTimelineRowPresentation(
          temporalState: .fading,
          titleOpacity: 0.82,
          metadataOpacity: 0.42,
          detailOpacity: 0.36,
          iconOpacity: 0.7,
          suppressDuration: true,
          relationLine: nil
        ),
        isLongTermResurfacing: false
      )
    }
    return item
  }

  private static func buildResurfacingItems(
    threads: [NoxContinuityThread],
    arcs: [NoxSemanticArc],
    evolution: NoxMemoryEvolutionSnapshot,
    profileMap: [String: NoxMemoryAgingProfile],
    period: NoxMemoryPeriod,
    at: Date
  ) -> [NoxTimelineBlockItem]? {
    guard period == .today else { return nil }
    guard !evolution.preferSparseSurfaces else { return nil }
    guard !evolution.longTermResurfacingNotes.isEmpty else { return nil }

    let resurfacingThread = threads.first { thread in
      profileMap[thread.id]?.band == .resurfacing
        && thread.sensitivityLevel == .normal
        && thread.confidence >= 0.5
    }
    let resurfacingArc = arcs.first { $0.continuityState == .resurfaced && $0.strength >= 0.5 }

    guard resurfacingThread != nil || resurfacingArc != nil else { return nil }

    let title = NoxTemporalContinuityCopyBuilder.longTermResurfacingTitle(
      thread: resurfacingThread,
      arc: resurfacingArc
    )
    let subtitle = NoxTemporalContinuityCopyBuilder.longTermResurfacingSubtitle(
      thread: resurfacingThread,
      arc: resurfacingArc,
      at: at
    )
    let presentation = NoxTimelineRowPresentation(
      temporalState: .resurfacing,
      titleOpacity: 0.94,
      metadataOpacity: 0.56,
      detailOpacity: 0.46,
      iconOpacity: 0.9,
      suppressDuration: true,
      relationLine: nil
    )

    return [
      NoxTimelineBlockItem(
        id: "long-term-resurfacing-\(resurfacingThread?.id ?? resurfacingArc?.id ?? "note")",
        timestamp: at,
        kind: .resurfacingMemory,
        title: title,
        subtitle: subtitle,
        detailLine: evolution.longTermResurfacingNotes.first,
        durationText: nil,
        category: nil,
        markerSymbol: NoxSFSymbol.validated("arrow.uturn.backward"),
        presentation: presentation,
        isLongTermResurfacing: true
      )
    ]
  }

  private static func injectResurfacing(
    _ items: [NoxTimelineBlockItem],
    into sections: [NoxTimelineSection]
  ) -> [NoxTimelineSection] {
    guard let continuityIndex = sections.firstIndex(where: { $0.layer == .continuity }) else {
      var copy = sections
      copy.insert(NoxTimelineSection(layer: .continuity, items: items), at: 0)
      return copy
    }
    var copy = sections
    let existing = copy[continuityIndex]
    let merged = items + existing.items.filter { !$0.isLongTermResurfacing }
    copy[continuityIndex] = NoxTimelineSection(layer: .continuity, items: merged)
    return copy
  }

  private static func agingInput(
    thread: NoxContinuityThread,
    weight: Double?,
    at: Date
  ) -> NoxMemoryAgingPresenter.Input {
    NoxMemoryAgingPresenter.Input(
      subjectId: thread.id,
      lastActiveAt: thread.lastSeenAt,
      recurrenceStrength: thread.recurrenceStrength,
      continuityGravity: thread.continuityStrength,
      temporalWeight: weight,
      confidence: thread.confidence,
      isResumed: thread.currentStatus == .resumed || thread.lastResumedAt != nil,
      at: at
    )
  }

  private static func stableDurationText(
    suppressDuration: Bool,
    temporalStamp: String?,
    fallback: String?
  ) -> String? {
    guard suppressDuration else { return fallback }
    return temporalStamp ?? fallback
  }
}
