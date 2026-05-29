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
import NoxShrineCore

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
                line: "Focus periods tend to stabilize when deep work sessions return repeatedly.",
                confidence: consistency.confidence
            ))
        }

        let resumptions = threads.filter { $0.totalResumptions >= 2 }.count
        if resumptions >= 2 {
            lines.append(NoxIdentityContinuityInsight(
                line: "Some interrupted workflows keep returning across sessions.",
                confidence: min(0.85, consistency.confidence + 0.1)
            ))
        }

        if consistency.recoversAfterOverload, !consistency.passiveDecompressionTendency {
            lines.append(NoxIdentityContinuityInsight(
                line: "After heavier work periods, the same workflows often reopen rather than staying closed.",
                confidence: consistency.confidence * 0.9
            ))
        } else if consistency.passiveDecompressionTendency {
            lines.append(NoxIdentityContinuityInsight(
                line: "Quiet recovery periods sometimes keep related workflows inactive for a while.",
                confidence: consistency.confidence * 0.85
            ))
        }

        if consistency.fragmentsEasily, behavioral.drift != nil {
            lines.append(NoxIdentityContinuityInsight(
                line: "When daily rhythms shift, activity fragments before patterns settle again.",
                confidence: consistency.confidence * 0.8
            ))
        }

        return Array(lines.prefix(2))
    }
}
