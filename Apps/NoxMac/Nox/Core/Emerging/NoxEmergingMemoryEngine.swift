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

enum NoxEmergingMemoryEngine {

    static func observe(
        semanticSpans: [NoxSemanticMemorySpan],
        openSpan: NoxSemanticMemorySpan?,
        threads: [NoxContinuityThread],
        stats: NoxMemoryDayStats,
        liveSignalCount: Int,
        continuitySeconds: TimeInterval
    ) -> (maturity: NoxMemoryMaturity, observations: [NoxEmergingMemoryObservation]) {
        let observations = buildObservations(
            semanticSpans: semanticSpans,
            openSpan: openSpan,
            threads: threads,
            stats: stats
        )
        let maturity = overallMaturity(
            spans: semanticSpans,
            openSpan: openSpan,
            threads: threads,
            stats: stats,
            liveSignalCount: liveSignalCount,
            continuitySeconds: continuitySeconds
        )
        return (maturity, observations)
    }

    static func primaryCopy(
        maturity: NoxMemoryMaturity,
        observations: [NoxEmergingMemoryObservation],
        readiness: NoxMemoryReadiness
    ) -> (title: String, detail: String) {
        if let first = observations.first {
            return (first.title, first.detail ?? readiness.emptyDetail)
        }
        return (readiness.emptyTitle(for: maturity), readiness.emptyDetail(for: maturity))
    }

    private static func buildObservations(
        semanticSpans: [NoxSemanticMemorySpan],
        openSpan: NoxSemanticMemorySpan?,
        threads: [NoxContinuityThread],
        stats: NoxMemoryDayStats
    ) -> [NoxEmergingMemoryObservation] {
        var results: [NoxEmergingMemoryObservation] = []

        if let cluster = transientCluster(from: semanticSpans, openSpan: openSpan, stats: stats) {
            results.append(cluster)
        }

        if let threadHint = emergingThreadHint(threads: threads) {
            results.append(threadHint)
        }

        if let fragmented = fragmentedRecurring(spans: semanticSpans, stats: stats) {
            results.append(fragmented)
        }

        return Array(results.prefix(4))
    }

    private static func transientCluster(
        from spans: [NoxSemanticMemorySpan],
        openSpan: NoxSemanticMemorySpan?,
        stats: NoxMemoryDayStats
    ) -> NoxEmergingMemoryObservation? {
        var titles = spans.map { $0.title.lowercased() }
        if let open = openSpan { titles.append(open.title.lowercased()) }

        let dev = titles.filter { $0.contains("development") || $0.contains("ai-assisted") }.count
        let research = titles.filter { $0.contains("research") || $0.contains("reading") }.count

        if dev >= 2 || (dev >= 1 && stats.totalActiveMs >= 120_000) {
            return NoxEmergingMemoryObservation(
                id: "emerging-dev",
                maturity: dev >= 2 ? .emerging : .transient,
                title: "Repeated development-related activity detected.",
                detail: "A recurring activity thread may be forming.",
                confidence: 0.55
            )
        }
        if research >= 2 {
            return NoxEmergingMemoryObservation(
                id: "emerging-research",
                maturity: .emerging,
                title: "Research activity is recurring, but attention remains fragmented.",
                detail: nil,
                confidence: 0.5
            )
        }
        if let open = openSpan, open.confidence >= NoxSemanticConfidence.transientThreshold {
            return NoxEmergingMemoryObservation(
                id: "transient-open",
                maturity: .transient,
                title: open.title,
                detail: "Still forming — not yet a durable memory span.",
                confidence: open.confidence
            )
        }
        return nil
    }

    private static func emergingThreadHint(threads: [NoxContinuityThread]) -> NoxEmergingMemoryObservation? {
        guard let candidate = threads
            .filter({ $0.decayState == .active && $0.totalSessions < 3 && $0.confidence >= 0.4 })
            .max(by: { $0.recurrenceStrength < $1.recurrenceStrength }) else {
            return nil
        }
        return NoxEmergingMemoryObservation(
            id: "thread-\(candidate.id)",
            maturity: .emerging,
            title: "A recurring activity thread may be forming.",
            detail: candidate.title,
            confidence: candidate.confidence
        )
    }

    private static func fragmentedRecurring(
        spans: [NoxSemanticMemorySpan],
        stats: NoxMemoryDayStats
    ) -> NoxEmergingMemoryObservation? {
        let fragmented = spans.filter {
            $0.semanticState == .fragmentedInteraction ||
            $0.title.lowercased().contains("fragmented")
        }.count
        guard fragmented >= 1, stats.appSwitchCount >= 4 else { return nil }
        return NoxEmergingMemoryObservation(
            id: "fragmented-recurring",
            maturity: fragmented >= 2 ? .stable : .transient,
            title: "App and workflow switching is recurring, but attention remains fragmented.",
            detail: nil,
            confidence: 0.48
        )
    }

    private static func overallMaturity(
        spans: [NoxSemanticMemorySpan],
        openSpan: NoxSemanticMemorySpan?,
        threads: [NoxContinuityThread],
        stats: NoxMemoryDayStats,
        liveSignalCount: Int,
        continuitySeconds: TimeInterval
    ) -> NoxMemoryMaturity {
        let durableThreads = threads.filter { $0.continuityStrength >= 0.65 && $0.totalSessions >= 3 }.count
        if durableThreads >= 2 || spans.count >= 6 { return .durable }
        if !spans.isEmpty || threads.count >= 2 { return .stable }
        if spans.count >= 1 || openSpan != nil || stats.totalActiveMs >= 90_000 { return .emerging }
        if liveSignalCount >= 2 || continuitySeconds >= 300 { return .transient }
        return .transient
    }
}
