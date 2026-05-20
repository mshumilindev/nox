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

nonisolated enum NoxAdaptiveContinuityModel {

    static func weights(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        signatures: [NoxBehavioralSignature],
        resurfacingFrequency: [String: Int] = [:]
    ) -> [NoxAdaptiveContinuityWeight] {
        threads.map { thread in
            let gravity = NoxContinuityImportanceModel.threadImportance(thread)
            var weight = (thread.continuityStrength * 0.55) + (gravity * 0.45)
            var reasons: [String] = ["base_strength", "continuity_gravity"]

            if thread.recurrenceStrength >= 0.5 {
                weight += 0.08
                reasons.append("recurrence")
            }
            if thread.totalResumptions >= 2 {
                weight += 0.06
                reasons.append("resumptions")
            }
            if signatures.contains(where: { $0.kind == .fragmentedContext }),
               thread.semanticType == .fragmentedWorkflow {
                weight += 0.05
                reasons.append("fragmented_alignment")
            }
            if arcs.contains(where: { $0.evolution == .strengthening && $0.strength >= 0.55 }) {
                weight += 0.04
                reasons.append("strengthening_arc_context")
            }
            if let hits = resurfacingFrequency[thread.id], hits >= 2 {
                weight -= 0.04
                reasons.append("recent_resurfacing")
            }

            return NoxAdaptiveContinuityWeight(
                threadId: thread.id,
                weight: min(1, max(0, weight)),
                reasons: reasons
            )
        }
        .sorted { $0.weight > $1.weight }
    }
}
