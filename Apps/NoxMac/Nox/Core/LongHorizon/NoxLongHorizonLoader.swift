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
        utilityCalibration: NoxAmbientUtilityCalibration = .neutral,
        memoryEvolution: NoxMemoryEvolutionSnapshot = .neutral,
        at date: Date = Date()
    ) -> NoxLongHorizonSnapshot {
        let filteredThreads = threads
            .filter { $0.decayState == .active || $0.currentStatus == .resumed }
        let threadPriority = mergedPriority(
            primary: memoryEvolution.prioritizedThreadIds,
            secondary: mergedPriority(
                primary: utilityCalibration.prioritizedThreadIds,
                secondary: behavioral.prioritizedThreadIds
            )
        )
        let activeThreads = orderThreads(
            filteredThreads,
            prioritizedIds: threadPriority,
            temporalWeights: memoryEvolution.temporalWeights
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

        let arcPriority = mergedPriority(
            primary: memoryEvolution.prioritizedArcIds,
            secondary: mergedPriority(
                primary: utilityCalibration.prioritizedArcIds,
                secondary: behavioral.prioritizedArcIds
            )
        )
        let orderedArcs = orderArcs(
            arcs,
            prioritizedIds: arcPriority,
            temporalWeights: memoryEvolution.temporalWeights
        )

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
            behavioralDrift: behavioral.drift,
            memoryEvolution: memoryEvolution
        )
    }

    private static func mergedPriority(primary: [String], secondary: [String]) -> [String] {
        var seen = Set<String>()
        var merged: [String] = []
        for id in primary + secondary where seen.insert(id).inserted {
            merged.append(id)
        }
        return merged
    }

    private static func orderThreads(
        _ threads: [NoxContinuityThread],
        prioritizedIds: [String],
        temporalWeights: [String: Double]
    ) -> [NoxContinuityThread] {
        let map = Dictionary(uniqueKeysWithValues: threads.map { ($0.id, $0) })
        var ordered: [NoxContinuityThread] = prioritizedIds.compactMap { map[$0] }
        let remainder = threads
            .filter { !prioritizedIds.contains($0.id) }
            .sorted { weightedThreadScore($0, weights: temporalWeights) > weightedThreadScore($1, weights: temporalWeights) }
        ordered.append(contentsOf: remainder)
        if prioritizedIds.isEmpty {
            return threads.sorted {
                weightedThreadScore($0, weights: temporalWeights) > weightedThreadScore($1, weights: temporalWeights)
            }
        }
        return ordered
    }

    private static func orderArcs(
        _ arcs: [NoxSemanticArc],
        prioritizedIds: [String],
        temporalWeights: [String: Double]
    ) -> [NoxSemanticArc] {
        let map = Dictionary(uniqueKeysWithValues: arcs.map { ($0.id, $0) })
        var ordered: [NoxSemanticArc] = prioritizedIds.compactMap { map[$0] }
        let remainder = arcs
            .filter { !prioritizedIds.contains($0.id) }
            .sorted { weightedArcScore($0, weights: temporalWeights) > weightedArcScore($1, weights: temporalWeights) }
        ordered.append(contentsOf: remainder)
        if prioritizedIds.isEmpty {
            return arcs.sorted {
                weightedArcScore($0, weights: temporalWeights) > weightedArcScore($1, weights: temporalWeights)
            }
        }
        return ordered
    }

    private static func weightedThreadScore(
        _ thread: NoxContinuityThread,
        weights: [String: Double]
    ) -> Double {
        let weight = weights[thread.id] ?? thread.continuityStrength
        let resumptionBoost = min(0.15, Double(thread.totalResumptions) * 0.03)
        let recurrenceBoost = thread.recurrenceStrength * 0.12
        return weight + resumptionBoost + recurrenceBoost
    }

    private static func weightedArcScore(_ arc: NoxSemanticArc, weights: [String: Double]) -> Double {
        let weight = weights[arc.id] ?? arc.strength
        let resurfacedBoost = arc.continuityState == .resurfaced ? 0.12 : 0
        let evolutionBoost = arc.evolution == .strengthening ? 0.08 : 0
        return weight + resurfacedBoost + evolutionBoost
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
