import Foundation

nonisolated enum NoxIdentityContinuityEngine {

    static func insights(
        consistency: NoxBehavioralConsistencyModel.Signature,
        threads: [NoxContinuityThread],
        behavioral: NoxBehavioralIntelligenceSnapshot
    ) -> [NoxIdentityContinuityInsight] {
        guard consistency.confidence >= 0.4 else { return [] }

        var lines: [NoxIdentityContinuityInsight] = []

        if consistency.stabilizesRhythm {
            lines.append(NoxIdentityContinuityInsight(
                line: "Continuity tends to stabilize when deep stretches return on familiar rails.",
                confidence: consistency.confidence
            ))
        }

        let resumptions = threads.filter { $0.totalResumptions >= 2 }.count
        if resumptions >= 2 {
            lines.append(NoxIdentityContinuityInsight(
                line: "Some interrupted structures keep finding their way back over time.",
                confidence: min(0.85, consistency.confidence + 0.1)
            ))
        }

        if consistency.recoversAfterOverload, !consistency.passiveDecompressionTendency {
            lines.append(NoxIdentityContinuityInsight(
                line: "After heavier stretches, continuity often reopens rather than staying closed.",
                confidence: consistency.confidence * 0.9
            ))
        } else if consistency.passiveDecompressionTendency {
            lines.append(NoxIdentityContinuityInsight(
                line: "Quiet recovery stretches sometimes hold continuity at a distance for a while.",
                confidence: consistency.confidence * 0.85
            ))
        }

        if consistency.fragmentsEasily, behavioral.drift != nil {
            lines.append(NoxIdentityContinuityInsight(
                line: "When rhythms drift, continuity fragments before it settles again.",
                confidence: consistency.confidence * 0.8
            ))
        }

        return Array(lines.prefix(2))
    }
}
