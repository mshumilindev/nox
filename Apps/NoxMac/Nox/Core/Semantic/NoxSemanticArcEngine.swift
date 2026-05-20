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

enum NoxSemanticArcEngine {

    private static let mergeGap: TimeInterval = 6 * 3600

    static func buildArcs(
    spans: [NoxSemanticMemorySpan],
    threads: [NoxContinuityThread],
    at date: Date = Date()
  ) -> [NoxSemanticArc] {
    var grouped: [NoxSemanticArcType: [NoxSemanticMemorySpan]] = [:]
    for span in spans where span.sensitivityLevel == .normal {
      let type = arcType(for: span)
      grouped[type, default: []].append(span)
    }

    var arcs: [NoxSemanticArc] = []
    for (type, bucket) in grouped {
      let clusters = clusterSpans(bucket.sorted { $0.startedAt < $1.startedAt })
      for (index, cluster) in clusters.enumerated() {
        arcs.append(makeArc(
          type: type,
          cluster: cluster,
          threads: threads,
          index: index,
          at: date
        ))
      }
    }

    return arcs
      .sorted { $0.strength > $1.strength }
      .prefix(8)
      .map { $0 }
  }

  private static func clusterSpans(_ spans: [NoxSemanticMemorySpan]) -> [[NoxSemanticMemorySpan]] {
    guard !spans.isEmpty else { return [] }
    var clusters: [[NoxSemanticMemorySpan]] = []
    var current: [NoxSemanticMemorySpan] = [spans[0]]

    for span in spans.dropFirst() {
      let lastEnd = current.last?.endedAt ?? current.last?.startedAt ?? span.startedAt
      if span.startedAt.timeIntervalSince(lastEnd) <= mergeGap {
        current.append(span)
      } else {
        clusters.append(current)
        current = [span]
      }
    }
    clusters.append(current)
    return clusters
  }

  private static func makeArc(
    type: NoxSemanticArcType,
    cluster: [NoxSemanticMemorySpan],
    threads: [NoxContinuityThread],
    index: Int,
    at date: Date
  ) -> NoxSemanticArc {
    let first = cluster.first?.startedAt ?? date
    let last = cluster.last?.endedAt ?? cluster.last?.startedAt ?? date
    let gap = date.timeIntervalSince(last)
    let avgConfidence = cluster.map(\.confidence).reduce(0, +) / Double(max(1, cluster.count))
    let relatedThread = threads.first { threadMatches($0, type: type) }

    let continuityState: NoxArcContinuityState
    if let thread = relatedThread, thread.totalResumptions > 0, gap < 48 * 3600 {
      continuityState = .resurfaced
    } else if gap < 12 * 3600 {
      continuityState = cluster.count >= 2 ? .merging : .active
    } else if gap < 7 * 24 * 3600 {
      continuityState = .fading
    } else {
      continuityState = .dormant
    }

    let evolution = evolutionFor(cluster: cluster, gap: gap)
    let strength = min(1.0, avgConfidence * 0.5 + Double(cluster.count) * 0.12 + (relatedThread?.recurrenceStrength ?? 0) * 0.3)

    return NoxSemanticArc(
      id: "\(type.rawValue)-\(index)-\(Int(first.timeIntervalSince1970))",
      label: label(for: type),
      arcType: type,
      continuityState: continuityState,
      evolution: evolution,
      spanCount: cluster.count,
      sessionTouches: relatedThread?.totalSessions ?? cluster.count,
      firstSeenAt: first,
      lastSeenAt: last,
      strength: strength,
      detailLine: detailLine(type: type, cluster: cluster, thread: relatedThread)
    )
  }

  private static func evolutionFor(cluster: [NoxSemanticMemorySpan], gap: TimeInterval) -> NoxArcEvolution {
    if gap > 5 * 24 * 3600 { return .decaying }
    let fragmented = cluster.filter { $0.semanticState == .fragmentedInteraction }.count
    if fragmented >= cluster.count / 2 + 1 { return .fragmenting }
    if cluster.count >= 3 { return .strengthening }
    return .stable
  }

  private static func arcType(for span: NoxSemanticMemorySpan) -> NoxSemanticArcType {
    let title = span.title.lowercased()
    switch span.fusionLabel {
    case .likelyAIAssistedWork: return .aiWorkflow
    case .likelyTravelPlanning: return .travelPlanning
    case .likelyResearch: return .research
    case .likelyCreativeWork: return .creativeExploration
    case .likelyCommunication: return .communication
    case .likelyPassiveEntertainment: return .passiveMedia
    default: break
    }
    if title.contains("fragmented") { return .fragmentedAttention }
    if title.contains("development") || title.contains("ai-assisted") { return .development }
    if title.contains("research") || title.contains("reading") { return .research }
    if title.contains("travel") { return .travelPlanning }
    if title.contains("creative") { return .creativeExploration }
    return .general
  }

  private static func threadMatches(_ thread: NoxContinuityThread, type: NoxSemanticArcType) -> Bool {
    switch (thread.semanticType, type) {
    case (.aiDevelopment, .aiWorkflow), (.aiDevelopment, .development),
         (.development, .development), (.research, .research),
         (.travelPlanning, .travelPlanning), (.fragmentedWorkflow, .fragmentedAttention):
      return true
    default:
      return false
    }
  }

  private static func label(for type: NoxSemanticArcType) -> String {
    switch type {
    case .aiWorkflow: return "AI workflow"
    case .development: return "Development"
    case .research: return "Research"
    case .travelPlanning: return "Travel planning"
    case .creativeExploration: return "Creative exploration"
    case .communication: return "Communication"
    case .passiveMedia: return "Passive media"
    case .fragmentedAttention: return "Fragmented attention"
    case .general: return "General context"
    }
  }

  private static func detailLine(
    type: NoxSemanticArcType,
    cluster: [NoxSemanticMemorySpan],
    thread: NoxContinuityThread?
  ) -> String? {
    if let thread, thread.totalResumptions >= 2 {
      return "Resurfaced across recent sessions"
    }
    if cluster.count >= 3 {
      return "\(cluster.count) memory spans woven together"
    }
    switch type {
    case .fragmentedAttention:
      return "May merge or fade with steadier focus"
    default:
      return nil
    }
  }
}
