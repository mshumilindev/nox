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

nonisolated enum NoxMemoryEvolutionOrchestrator {

    static func evolve(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        typedMemories: [NoxTypedMemoryEntity],
        gravity: [String: Double],
        behavioral: NoxBehavioralIntelligenceSnapshot,
        calibration: NoxAmbientUtilityCalibration,
        focus: NoxFocusAnalysis?,
        stored: inout NoxMemoryEvolutionState,
        calmnessAllowsResurfacing: Bool,
        at date: Date = Date()
    ) -> NoxMemoryEvolutionSnapshot {
        let agingProfiles = NoxMemoryAgingEngine.profiles(threads: threads, arcs: arcs, at: date)
        let resilience = NoxContinuityResilienceEngine.scores(
            threads: threads,
            arcs: arcs,
            focus: focus
        )

        var temporalWeights = stored.temporalWeights
        temporalWeights = NoxTemporalWeightEvolutionEngine.evolve(
            threads: threads,
            arcs: arcs,
            agingProfiles: agingProfiles,
            gravity: gravity,
            resilience: resilience,
            stored: &temporalWeights,
            at: date
        )
        stored.temporalWeights = temporalWeights

        var eraResonance = stored.eraResonance
        let eraHints = NoxEraEvolutionEngine.evolve(
            typedMemories: typedMemories,
            stored: &eraResonance,
            agingProfiles: agingProfiles,
            at: date
        )
        stored.eraResonance = eraResonance

        var unresolvedReturns = stored.unresolvedReturnCounts
        let unresolved = NoxUnresolvedPersistenceEngine.signals(
            threads: threads,
            arcs: arcs,
            storedReturns: &unresolvedReturns,
            at: date
        )
        stored.unresolvedReturnCounts = unresolvedReturns

        var ecologyCoupling = stored.ecologyCoupling
        let ecologyNotes = NoxMemoryEcologyEngine.evolve(
            threads: threads,
            arcs: arcs,
            agingProfiles: agingProfiles,
            temporalWeights: &temporalWeights,
            storedCoupling: &ecologyCoupling
        )
        stored.ecologyCoupling = ecologyCoupling
        stored.temporalWeights = temporalWeights

        let longHorizonStructures = NoxLongHorizonContinuityEngine.structures(
            threads: threads,
            arcs: arcs,
            temporalWeights: temporalWeights,
            at: date
        )

        let consistency = NoxBehavioralConsistencyModel.infer(
            behavioral: behavioral,
            focus: focus,
            calibration: calibration
        )
        let identityInsights = NoxIdentityContinuityEngine.insights(
            consistency: consistency,
            threads: threads,
            behavioral: behavioral
        )

        let prioritizedThreadIds = temporalWeights
            .filter { threads.map(\.id).contains($0.key) }
            .sorted { $0.value > $1.value }
            .prefix(6)
            .map(\.key)

        let prioritizedArcIds = temporalWeights
            .filter { arcs.map(\.id).contains($0.key) }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map(\.key)

        let preferSparse = calibration.preferSilence
            || calibration.globalRestraint < 0.75
            || calibration.recoveryQuality.suppressResurfacing

        let longTermNotes = NoxLongTermResurfacingEngine.notes(
            threads: threads,
            arcs: arcs,
            agingProfiles: agingProfiles,
            unresolved: unresolved,
            lastShownAt: stored.lastLongTermResurfacingAt,
            preferSilence: preferSparse,
            at: date
        )
        if !longTermNotes.isEmpty {
            stored.lastLongTermResurfacingAt = date
        }

        stored.lastEvolutionAt = date

        let draft = NoxMemoryEvolutionSnapshot(
            agingProfiles: agingProfiles,
            longHorizonStructures: longHorizonStructures,
            identityInsights: identityInsights,
            eraHints: eraHints,
            unresolvedSignals: unresolved,
            ecologyNotes: ecologyNotes,
            temporalWeights: temporalWeights,
            resilienceScores: resilience,
            longTermResurfacingNotes: longTermNotes,
            temporalCoherenceLine: nil,
            prioritizedThreadIds: prioritizedThreadIds,
            prioritizedArcIds: prioritizedArcIds,
            preferSparseSurfaces: preferSparse
        )

        return NoxTemporalCoherenceEngine.tune(
            snapshot: draft,
            calmnessAllowsResurfacing: calmnessAllowsResurfacing
        )
    }
}
