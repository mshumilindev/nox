import Foundation

@MainActor
enum NoxBehavioralIntelligenceOrchestrator {

    static func refresh(
        paused: Bool,
        connectorSnapshot: NoxConnectorContinuitySnapshot,
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        spans: [NoxActivitySpan],
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        weeklyRollups: [NoxMemoryRollupSnapshot],
        monthlyRollups: [NoxMemoryRollupSnapshot],
        recentDailyDensity: [Double],
        lastInterventionAt: Date?,
        signalStore: NoxBehavioralIntelligenceSignalStore,
        at date: Date = Date()
    ) async -> NoxBehavioralIntelligenceSnapshot {
        guard !paused else { return .empty }

        let storedSignatures = (try? await signalStore.recentSignatures()) ?? []

        let signatures = NoxBehavioralPatternEngine.detect(
            stats: stats,
            focus: focus,
            spans: spans,
            connectorCadence: connectorSnapshot.cadencePatterns,
            recentDailyDensity: recentDailyDensity,
            weeklyRollups: weeklyRollups,
            at: date
        )

        let expectations = NoxContextualExpectationEngine.build(
            signatures: signatures,
            cadencePatterns: connectorSnapshot.cadencePatterns,
            recentDailyDensity: recentDailyDensity,
            stats: stats,
            at: date
        )

        let continuityWeights = NoxAdaptiveContinuityModel.weights(
            threads: threads,
            arcs: arcs,
            signatures: signatures
        )

        let temporalRhythms = NoxTemporalRhythmEngine.infer(
            weeklyRollups: weeklyRollups,
            monthlyRollups: monthlyRollups,
            signatures: signatures,
            recentDailyDensity: recentDailyDensity
        )

        let lifeStructures = NoxEmergentStructureEngine.candidates(
            signatures: signatures,
            arcs: arcs,
            monthlyRollups: monthlyRollups,
            expectations: expectations
        )

        let drift = NoxBehavioralDriftEngine.detect(
            recentDailyDensity: recentDailyDensity,
            stats: stats,
            focus: focus,
            signatures: signatures,
            at: date
        )

        let orchestration = NoxOrchestrationSignalLayer.build(
            stats: stats,
            focus: focus,
            connectorSnapshot: connectorSnapshot,
            signatures: signatures,
            drift: drift,
            at: date
        )

        let prioritization = NoxContextualMemoryPrioritizer.prioritize(
            threads: threads,
            arcs: arcs,
            weights: continuityWeights,
            signatures: signatures,
            lifeStructures: lifeStructures,
            drift: drift,
            existingNotes: connectorSnapshot.enrichmentNotes
        )

        let intervention = NoxAdaptiveInterventionTimingEngine.evaluate(
            connectorSnapshot: connectorSnapshot,
            orchestration: orchestration,
            signatures: signatures,
            drift: drift,
            lastInterventionAt: lastInterventionAt,
            at: date
        )

        var enrichmentNotes: [String] = []
        for signature in signatures.prefix(2) {
            enrichmentNotes.append(signature.detail)
        }
        enrichmentNotes.append(contentsOf: prioritization.resurfacingNotes)

        let snapshot = NoxBehavioralIntelligenceSnapshot(
            signatures: signatures,
            expectations: expectations,
            continuityWeights: continuityWeights,
            temporalRhythms: temporalRhythms,
            lifeStructures: lifeStructures,
            drift: drift,
            orchestration: orchestration,
            enrichmentNotes: enrichmentNotes,
            prioritizedThreadIds: prioritization.threadIds,
            prioritizedArcIds: prioritization.arcIds,
            recommendedIntervention: intervention
        )

        try? await signalStore.appendSignatures(signatures)
        _ = storedSignatures

        return snapshot
    }
}
