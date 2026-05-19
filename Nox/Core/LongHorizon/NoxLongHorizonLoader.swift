import Foundation

enum NoxLongHorizonLoader {

    static func load(
        threads: [NoxContinuityThread],
        semanticSpans: [NoxSemanticMemorySpan],
        typedMemories: [NoxTypedMemoryEntity],
        weeklyRollups: [NoxMemoryRollupSnapshot],
        monthlyRollups: [NoxMemoryRollupSnapshot],
        reflections: [NoxReflectionCandidate],
        emerging: [NoxEmergingMemoryObservation],
        arcs: [NoxSemanticArc],
        resurfacingNotes: [String],
        connectorCadencePatterns: [NoxCadencePattern] = [],
        connectorEnrichmentNotes: [String] = [],
        behavioral: NoxBehavioralIntelligenceSnapshot = .empty,
        at date: Date = Date()
    ) -> NoxLongHorizonSnapshot {
        let filteredThreads = threads
            .filter { $0.decayState == .active || $0.currentStatus == .resumed }
        let activeThreads = orderThreads(
            filteredThreads,
            prioritizedIds: behavioral.prioritizedThreadIds
        )
        .prefix(6)
        .map { $0 }

        let rhythms = typedMemories
            .filter { $0.kind == .behavioralRhythm && !$0.isExcludedFromAnalysis }
            .prefix(4)
            .map { $0 }

        let eras = typedMemories
            .filter { $0.kind == .projectArc || $0.sourceHorizon == .era }
            .prefix(3)
            .map { $0 }

        let narratives = buildNarratives(
            weekly: weeklyRollups,
            monthly: monthlyRollups
        )

        let recentContinuities = threads
            .filter { $0.lastResumedAt != nil }
            .sorted { ($0.lastResumedAt ?? .distantPast) > ($1.lastResumedAt ?? .distantPast) }
            .prefix(4)
            .map { NoxContinuityResurfacingPresenter.threadDisplayTitle($0) }

        let orderedArcs = orderArcs(arcs, prioritizedIds: behavioral.prioritizedArcIds)

        return NoxLongHorizonSnapshot(
            activeThreads: activeThreads,
            emergingPatterns: emerging,
            recentContinuities: recentContinuities,
            longHorizonNarratives: narratives,
            behavioralRhythms: rhythms,
            eraCandidates: eras,
            semanticArcs: orderedArcs,
            reflections: reflections,
            resurfacingNotes: resurfacingNotes,
            connectorCadencePatterns: connectorCadencePatterns,
            connectorEnrichmentNotes: connectorEnrichmentNotes,
            behavioralSignatures: behavioral.signatures.filter(\.isGated),
            temporalRhythmInsights: NoxPatternConfidenceModel.gate(
                behavioral.temporalRhythms,
                confidence: \.confidence,
                limit: 4
            ),
            lifeStructureCandidates: NoxPatternConfidenceModel.gate(
                behavioral.lifeStructures,
                confidence: \.confidence,
                limit: 3
            ),
            behavioralDrift: behavioral.drift
        )
    }

    private static func orderThreads(
        _ threads: [NoxContinuityThread],
        prioritizedIds: [String]
    ) -> [NoxContinuityThread] {
        guard !prioritizedIds.isEmpty else {
            return threads.sorted { $0.continuityStrength > $1.continuityStrength }
        }
        let map = Dictionary(uniqueKeysWithValues: threads.map { ($0.id, $0) })
        var ordered: [NoxContinuityThread] = prioritizedIds.compactMap { map[$0] }
        for thread in threads where !prioritizedIds.contains(thread.id) {
            ordered.append(thread)
        }
        return ordered
    }

    private static func orderArcs(
        _ arcs: [NoxSemanticArc],
        prioritizedIds: [String]
    ) -> [NoxSemanticArc] {
        guard !prioritizedIds.isEmpty else {
            return arcs.sorted { $0.strength > $1.strength }
        }
        let map = Dictionary(uniqueKeysWithValues: arcs.map { ($0.id, $0) })
        var ordered: [NoxSemanticArc] = prioritizedIds.compactMap { map[$0] }
        for arc in arcs where !prioritizedIds.contains(arc.id) {
            ordered.append(arc)
        }
        return ordered
    }

    private static func buildNarratives(
        weekly: [NoxMemoryRollupSnapshot],
        monthly: [NoxMemoryRollupSnapshot]
    ) -> [NoxLongHorizonNarrative] {
        var results: [NoxLongHorizonNarrative] = []
        for rollup in weekly.suffix(2) {
            results.append(NoxLongHorizonNarrative(
                id: rollup.id,
                horizonLabel: "This week",
                summary: rollup.summaryText,
                periodStart: rollup.periodStart
            ))
        }
        for rollup in monthly.suffix(1) {
            results.append(NoxLongHorizonNarrative(
                id: rollup.id,
                horizonLabel: "This month",
                summary: rollup.summaryText,
                periodStart: rollup.periodStart
            ))
        }
        return results
    }
}
