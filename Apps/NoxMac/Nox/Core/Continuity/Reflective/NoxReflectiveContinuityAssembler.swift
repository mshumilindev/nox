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

struct NoxReflectiveContinuityBundle: Equatable, Sendable {
    let longHorizon: NoxLongHorizonSnapshot
    let morningSummary: NoxMorningSummary?
    let memoryMaturity: NoxMemoryMaturity
    let emergingObservations: [NoxEmergingMemoryObservation]
}

@MainActor
enum NoxReflectiveContinuityAssembler {

    static func assemble(
        period: NoxMemoryPeriod,
        threads: [NoxContinuityThread],
        semanticSpans: [NoxSemanticMemorySpan],
        openSpan: NoxSemanticMemorySpan?,
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        typedMemories: [NoxTypedMemoryEntity],
        weeklyRollups: [NoxMemoryRollupSnapshot],
        monthlyRollups: [NoxMemoryRollupSnapshot],
        reflectionStore: NoxReflectionStore,
        continuityNote: String?,
        lastShutdownAt: Date?,
        lastMorningAt: Date?,
        lastResurfacingShownAt: Date?,
        liveSignalCount: Int,
        continuitySeconds: TimeInterval,
        connectorSnapshot: NoxConnectorContinuitySnapshot = .empty,
        behavioralSnapshot: NoxBehavioralIntelligenceSnapshot = .empty,
        calmnessProfile: NoxAdaptiveCalmnessProfile = .balanced,
        utilityCalibration: NoxAmbientUtilityCalibration = .neutral,
        memoryEvolution: NoxMemoryEvolutionSnapshot = .neutral,
        at date: Date = Date()
    ) async throws -> NoxReflectiveContinuityBundle {
        let arcs = NoxSemanticArcEngine.buildArcs(spans: semanticSpans, threads: threads, at: date)
        let connectorEnrichmentNotes = NoxConnectorContinuityEnricher.enrichmentNotes(
            snapshot: connectorSnapshot,
            arcs: arcs,
            threads: threads
        )

        let emergingResult = NoxEmergingMemoryEngine.observe(
            semanticSpans: semanticSpans,
            openSpan: openSpan,
            threads: threads,
            stats: stats,
            liveSignalCount: liveSignalCount,
            continuitySeconds: continuitySeconds
        )

        var reflections = (try? await reflectionStore.recent(limit: 6)) ?? []
        let lastReflection = try? await reflectionStore.lastCreatedAt()
        let reflectionInput = NoxReflectionInputBuilder.build(
            period: period,
            spans: semanticSpans,
            threads: threads,
            arcs: arcs,
            stats: stats,
            focus: focus,
            weeklyRollups: weeklyRollups,
            behavioral: behavioralSnapshot,
            at: date
        )

        if NoxReflectiveSynthesisEngine.shouldSynthesize(
            lastReflectionAt: lastReflection,
            calmness: calmnessProfile,
            at: date
        ) {
            let raw = NoxReflectiveSynthesisEngine.synthesize(input: reflectionInput, at: date)
            let fresh = NoxContinuityMaturityOrchestrator.matureReflections(
                raw,
                input: reflectionInput,
                stored: reflections,
                threads: threads,
                arcs: arcs,
                behavioral: behavioralSnapshot,
                focus: focus,
                connectorSnapshot: connectorSnapshot,
                at: date
            )
            for candidate in fresh {
                try? await reflectionStore.upsert(candidate)
            }
            if !fresh.isEmpty {
                reflections = fresh + reflections
            }
        }

        let displayReflections = NoxContinuityMaturityOrchestrator.matureReflections(
            NoxReflectionPresenter.distinct(reflections, limit: 6),
            input: reflectionInput,
            stored: reflections,
            threads: threads,
            arcs: arcs,
            behavioral: behavioralSnapshot,
            focus: focus,
            connectorSnapshot: connectorSnapshot,
            at: date
        )

        var resurfacingNotes: [String] = []
        let resurfacingDepth = NoxLongHorizonRelevanceEngine.resurfacingDepthMultiplier(
            calibration: utilityCalibration
        )
        if calmnessProfile.allowsResurfacing,
           utilityCalibration.recoveryQuality.allowGentleContinuity,
           resurfacingDepth >= 0.35 {
            resurfacingNotes = NoxContinuityResurfacingOrchestrator.resurfacingNotes(
                threads: threads,
                arcs: arcs,
                lastShownAt: lastResurfacingShownAt,
                at: date
            )
            if resurfacingDepth < 0.55 {
                resurfacingNotes = Array(resurfacingNotes.prefix(1))
            }
        }
        for note in NoxContinuityMaturityOrchestrator.matureEnrichmentNotes(connectorEnrichmentNotes)
            where !resurfacingNotes.contains(note) {
            resurfacingNotes.append(note)
        }
        for note in NoxContinuityMaturityOrchestrator.matureEnrichmentNotes(
            NoxBehavioralIntelligenceEnricher.enrichmentNotes(snapshot: behavioralSnapshot)
        ) where !resurfacingNotes.contains(note) {
            resurfacingNotes.append(note)
        }
        resurfacingNotes = NoxContinuityMaturityOrchestrator.matureResurfacingNotes(resurfacingNotes)

        if calmnessProfile.allowsResurfacing,
           !memoryEvolution.preferSparseSurfaces {
            for note in memoryEvolution.longTermResurfacingNotes where !resurfacingNotes.contains(note) {
                resurfacingNotes.append(note)
            }
        }
        resurfacingNotes = Array(resurfacingNotes.prefix(memoryEvolution.preferSparseSurfaces ? 2 : 3))

        var longHorizon = NoxLongHorizonLoader.load(
            threads: threads,
            semanticSpans: semanticSpans,
            typedMemories: typedMemories,
            weeklyRollups: weeklyRollups,
            monthlyRollups: monthlyRollups,
            reflections: displayReflections,
            emerging: emergingResult.observations,
            arcs: arcs,
            resurfacingNotes: resurfacingNotes,
            connectorCadencePatterns: connectorSnapshot.cadencePatterns,
            connectorEnrichmentNotes: connectorEnrichmentNotes,
            behavioral: behavioralSnapshot,
            utilityCalibration: utilityCalibration,
            memoryEvolution: memoryEvolution
        )
        longHorizon = NoxLongHorizonMaturityEngine.mature(
            snapshot: longHorizon,
            threads: threads,
            arcs: arcs,
            at: date
        )

        var morningSummary: NoxMorningSummary?
        if let trigger = NoxMorningContinuityEngine.shouldGenerate(
            at: date,
            lastGeneratedAt: lastMorningAt,
            lastShutdownAt: lastShutdownAt
        ) {
            let snapshot = NoxMorningContinuityEngine.buildSnapshot(
                trigger: trigger,
                at: date,
                threads: threads,
                semanticSpans: semanticSpans,
                stats: stats,
                focus: focus,
                continuityNote: continuityNote,
                lastShutdownAt: lastShutdownAt
            )
            morningSummary = NoxMorningSummaryPresenter.present(snapshot: snapshot)
        }

        return NoxReflectiveContinuityBundle(
            longHorizon: longHorizon,
            morningSummary: morningSummary,
            memoryMaturity: emergingResult.maturity,
            emergingObservations: emergingResult.observations
        )
    }
}
