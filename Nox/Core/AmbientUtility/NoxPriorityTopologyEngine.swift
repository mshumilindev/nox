import Foundation

nonisolated enum NoxPriorityTopologyEngine {

    static func structuralWeights(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        stats: NoxMemoryDayStats,
        behavioral: NoxBehavioralIntelligenceSnapshot,
        at date: Date = Date()
    ) -> [NoxStructuralContinuityWeight] {
        var weights: [NoxStructuralContinuityWeight] = []

        for thread in threads {
            let importance = NoxContinuityImportanceModel.threadImportance(thread, at: date)
            let kind: NoxStructuralContinuityKind
            if thread.totalResumptions >= 2 && thread.decayState != .active {
                kind = .unresolved
            } else if thread.recurrenceStrength >= 0.55 {
                kind = .recurringReturn
            } else if thread.continuityStrength >= 0.65 {
                kind = .sustainedEngagement
            } else if thread.semanticType == .fragmentedWorkflow {
                kind = .fragmentationLoop
            } else {
                kind = .stabilizingRhythm
            }
            weights.append(NoxStructuralContinuityWeight(
                subjectId: thread.id,
                label: thread.title.replacingOccurrences(of: " continuity", with: ""),
                weight: importance,
                kind: kind
            ))
        }

        if stats.appSwitchCount >= 16, stats.focusedMs < stats.fragmentedMs {
            weights.append(NoxStructuralContinuityWeight(
                subjectId: "topology-attention-sink",
                label: "Scattered attention",
                weight: 0.55,
                kind: .attentionSink
            ))
        }

        for arc in arcs.filter({ $0.continuityState == .resurfaced }).prefix(2) {
            weights.append(NoxStructuralContinuityWeight(
                subjectId: arc.id,
                label: arc.label,
                weight: NoxContinuityImportanceModel.arcImportance(arc),
                kind: .unresolved
            ))
        }

        if behavioral.signatures.contains(where: { $0.kind == .instabilityPhase }) {
            weights.append(NoxStructuralContinuityWeight(
                subjectId: "topology-unstable-rhythm",
                label: "Unsettled rhythm",
                weight: 0.5,
                kind: .fragmentationLoop
            ))
        }

        return weights
            .sorted { $0.weight > $1.weight }
            .prefix(8)
            .map { $0 }
    }
}
