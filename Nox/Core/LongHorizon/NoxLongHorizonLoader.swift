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
        at date: Date = Date()
    ) -> NoxLongHorizonSnapshot {
        let activeThreads = threads
            .filter { $0.decayState == .active || $0.currentStatus == .resumed }
            .sorted { $0.continuityStrength > $1.continuityStrength }
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

        return NoxLongHorizonSnapshot(
            activeThreads: activeThreads,
            emergingPatterns: emerging,
            recentContinuities: recentContinuities,
            longHorizonNarratives: narratives,
            behavioralRhythms: rhythms,
            eraCandidates: eras,
            semanticArcs: arcs,
            reflections: reflections,
            resurfacingNotes: resurfacingNotes,
            connectorCadencePatterns: connectorCadencePatterns,
            connectorEnrichmentNotes: connectorEnrichmentNotes
        )
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
