import Foundation

nonisolated enum NoxLongHorizonMaturityEngine {

    static func mature(
        snapshot: NoxLongHorizonSnapshot,
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        at date: Date = Date()
    ) -> NoxLongHorizonSnapshot {
        let gravityOrderedThreads = threads
            .filter { $0.decayState == .active || $0.currentStatus == .resumed }
            .sorted {
                NoxContinuityImportanceModel.threadImportance($0, at: date) >
                    NoxContinuityImportanceModel.threadImportance($1, at: date)
            }
            .prefix(5)
            .map { $0 }

        let gravityOrderedArcs = arcs
            .sorted { NoxContinuityImportanceModel.arcImportance($0) > NoxContinuityImportanceModel.arcImportance($1) }
            .prefix(6)
            .map { $0 }

        let maturedReflections = snapshot.reflections
        let maturedNotes = snapshot.resurfacingNotes
            .map { NoxBehavioralHumilityLayer.softenResurfacingNote($0) }
            .filter { !$0.isEmpty }
            .uniqued()
            .prefix(3)
            .map { $0 }

        let humbledSignatures = snapshot.behavioralSignatures
            .filter(\.isGated)
            .prefix(1)
            .map { sig in
                NoxBehavioralSignature(
                    id: sig.id,
                    kind: sig.kind,
                    label: "",
                    detail: NoxBehavioralHumilityLayer.softenEnrichmentNote(sig.detail),
                    confidence: sig.confidence,
                    horizonDays: sig.horizonDays,
                    evidence: sig.evidence
                )
            }
        let drift = snapshot.behavioralDrift.map { NoxBehavioralHumilityLayer.softenDrift($0) }
        let structures = snapshot.lifeStructureCandidates
            .prefix(2)
            .map { NoxBehavioralHumilityLayer.softenLifeStructure($0) }

        let narratives = snapshot.longHorizonNarratives.map { narrative in
            NoxLongHorizonNarrative(
                id: narrative.id,
                horizonLabel: narrative.horizonLabel,
                summary: NoxReflectiveLanguageSoftener.soften(narrative.summary),
                periodStart: narrative.periodStart
            )
        }

        return NoxLongHorizonSnapshot(
            activeThreads: snapshot.activeThreads.isEmpty ? Array(gravityOrderedThreads) : snapshot.activeThreads,
            emergingPatterns: Array(snapshot.emergingPatterns.prefix(3)),
            recentContinuities: snapshot.recentContinuities,
            longHorizonNarratives: narratives,
            behavioralRhythms: snapshot.behavioralRhythms,
            eraCandidates: snapshot.eraCandidates,
            semanticArcs: snapshot.semanticArcs.isEmpty ? Array(gravityOrderedArcs) : snapshot.semanticArcs,
            reflections: maturedReflections,
            resurfacingNotes: Array(maturedNotes),
            connectorCadencePatterns: snapshot.connectorCadencePatterns,
            connectorEnrichmentNotes: snapshot.connectorEnrichmentNotes
                .map { NoxBehavioralHumilityLayer.softenEnrichmentNote($0) }
                .prefix(3)
                .map { $0 },
            behavioralSignatures: Array(humbledSignatures),
            temporalRhythmInsights: Array(snapshot.temporalRhythmInsights.prefix(2)),
            lifeStructureCandidates: Array(structures),
            behavioralDrift: drift
        )
    }
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0.lowercased()).inserted }
    }
}
