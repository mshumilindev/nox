import Foundation

nonisolated enum NoxExperientialPriorityEngine {

    static func priorities(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        gravity: [String: Double],
        stats: NoxMemoryDayStats,
        behavioral: NoxBehavioralIntelligenceSnapshot,
        at date: Date = Date()
    ) -> [NoxExperientialPriority] {
        var results: [NoxExperientialPriority] = []

        for thread in threads {
            let g = gravity[thread.id] ?? NoxContinuityImportanceModel.threadImportance(thread, at: date)
            let stabilizes = thread.recurrenceStrength >= 0.5 && thread.continuityStrength >= 0.55
            var significance = g

            if thread.semanticType == .fragmentedWorkflow {
                significance *= 0.85
            }
            if thread.totalResumptions >= 2, thread.lastResumedAt != nil {
                let gap = date.timeIntervalSince(thread.lastResumedAt!)
                if gap < 48 * 3600 { significance += 0.08 }
            }
            if thread.decayState == .fading, stats.appSwitchCount >= 10 {
                significance *= 0.75
            }

            results.append(NoxExperientialPriority(
                subjectId: thread.id,
                label: thread.title.replacingOccurrences(of: " continuity", with: ""),
                significance: min(1, significance),
                stabilizesRhythm: stabilizes
            ))
        }

        for arc in arcs where arc.strength >= 0.45 {
            let g = gravity[arc.id] ?? arc.strength
            results.append(NoxExperientialPriority(
                subjectId: arc.id,
                label: arc.label,
                significance: g,
                stabilizesRhythm: arc.evolution == .strengthening
            ))
        }

        if behavioral.signatures.contains(where: { $0.kind == .instabilityPhase }) {
            results.append(NoxExperientialPriority(
                subjectId: "experiential-instability",
                label: "Unsettled stretch",
                significance: 0.48,
                stabilizesRhythm: false
            ))
        }

        return results
            .sorted { $0.significance > $1.significance }
            .prefix(8)
            .map { $0 }
    }
}
