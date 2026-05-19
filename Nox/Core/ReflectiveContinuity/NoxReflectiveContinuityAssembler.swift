import Foundation

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

        var reflections = (try? await reflectionStore.recent(limit: 4)) ?? []
        let lastReflection = try? await reflectionStore.lastCreatedAt()

        if NoxReflectiveSynthesisEngine.shouldSynthesize(lastReflectionAt: lastReflection, at: date) {
            let input = NoxReflectionInputBuilder.build(
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
            let fresh = NoxReflectiveSynthesisEngine.synthesize(input: input, at: date)
            for candidate in fresh {
                try? await reflectionStore.upsert(candidate)
            }
            if !fresh.isEmpty {
                reflections = fresh + reflections
            }
        }

        var resurfacingNotes = NoxContinuityResurfacingOrchestrator.resurfacingNotes(
            threads: threads,
            arcs: arcs,
            lastShownAt: lastResurfacingShownAt,
            at: date
        )
        for note in connectorEnrichmentNotes where !resurfacingNotes.contains(note) {
            resurfacingNotes.append(note)
        }
        for note in NoxBehavioralIntelligenceEnricher.enrichmentNotes(snapshot: behavioralSnapshot)
            where !resurfacingNotes.contains(note) {
            resurfacingNotes.append(note)
        }

        let longHorizon = NoxLongHorizonLoader.load(
            threads: threads,
            semanticSpans: semanticSpans,
            typedMemories: typedMemories,
            weeklyRollups: weeklyRollups,
            monthlyRollups: monthlyRollups,
            reflections: NoxReflectionPresenter.distinct(reflections, limit: 4),
            emerging: emergingResult.observations,
            arcs: arcs,
            resurfacingNotes: resurfacingNotes,
            connectorCadencePatterns: connectorSnapshot.cadencePatterns,
            connectorEnrichmentNotes: connectorEnrichmentNotes,
            behavioral: behavioralSnapshot
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
