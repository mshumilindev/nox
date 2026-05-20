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

nonisolated enum NoxContinuityMaturityOrchestrator {

    static func matureReflections(
        _ candidates: [NoxReflectionCandidate],
        input: NoxReflectionInput,
        stored: [NoxReflectionCandidate],
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        behavioral: NoxBehavioralIntelligenceSnapshot,
        focus: NoxFocusAnalysis?,
        connectorSnapshot: NoxConnectorContinuitySnapshot,
        at date: Date = Date()
    ) -> [NoxReflectionCandidate] {
        let context = NoxContinuityMaturityContext.build(
            input: input,
            focus: focus,
            behavioral: behavioral,
            connectorSnapshot: connectorSnapshot
        )

        var matured: [NoxMaturedReflection] = []
        for candidate in candidates {
            let gravity = NoxContinuityGravityEngine.reflectionGravity(
                reflectionId: candidate.id,
                input: input,
                threads: threads,
                arcs: arcs,
                behavioral: behavioral,
                at: date
            )
            guard NoxContextualRelevanceFilter.isRelevant(
                reflectionId: candidate.id,
                gravity: gravity,
                context: context
            ) else { continue }

            let salience = NoxContinuitySalienceModel.salience(
                reflectionId: candidate.id,
                gravity: gravity,
                input: input,
                arcs: arcs
            )
            let naturalized = NoxReflectionNaturalizationEngine.naturalize(
                candidate,
                input: input,
                salience: salience
            )
            let weightedConfidence = min(1, naturalized.confidence * (0.72 + gravity * 0.28))
            let adjusted = NoxReflectionCandidate(
                id: naturalized.id,
                text: naturalized.text,
                detailLine: naturalized.detailLine,
                confidence: weightedConfidence,
                createdAt: naturalized.createdAt,
                sourceSignals: naturalized.sourceSignals
            )
            matured.append(NoxMaturedReflection(
                candidate: adjusted,
                gravity: gravity,
                salience: salience
            ))
        }

        let filtered = matured
            .filter { !NoxReflectionSuppressionEngine.shouldSuppress(
                matured: $0,
                stored: stored,
                context: context,
                at: date
            ) }
            .sorted {
                if abs($0.gravity - $1.gravity) > 0.04 { return $0.gravity > $1.gravity }
                return $0.candidate.confidence > $1.candidate.confidence
            }

        let topGravity = filtered.first?.gravity ?? 0
        let limit = NoxReflectionSuppressionEngine.displayLimit(topGravity: topGravity)

        return NoxReflectionPresenter.distinct(
            filtered.prefix(limit).map(\.candidate),
            limit: limit
        )
    }

    static func matureEnrichmentNotes(_ notes: [String]) -> [String] {
        notes
            .map { NoxBehavioralHumilityLayer.softenEnrichmentNote($0) }
            .filter { !$0.isEmpty }
            .uniqued()
            .prefix(3)
            .map { $0 }
    }

    static func matureResurfacingNotes(_ notes: [String]) -> [String] {
        notes
            .map { NoxBehavioralHumilityLayer.softenResurfacingNote($0) }
            .filter { !$0.isEmpty }
            .uniqued()
            .prefix(2)
            .map { $0 }
    }
}
