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

nonisolated enum NoxInterventionReceptivenessModel {

    static func evaluate(
        focus: NoxFocusAnalysis?,
        stats: NoxMemoryDayStats,
        behavioral: NoxBehavioralIntelligenceSnapshot,
        decompression: NoxDecompressionState
    ) -> NoxInterventionReceptiveness {
        let interruptionSensitive = behavioral.orchestration.signals.contains {
            $0.kind == .highInterruptionSensitivity && $0.level >= 0.55
        }
        let deepFocus = focus?.kind == .deepWork
            || behavioral.orchestration.signals.contains { $0.kind == .deepFocusStability && $0.level >= 0.65 }
        let fragmented = focus?.kind == .fragmented || stats.appSwitchCount >= 14
        let passive = behavioral.signatures.contains { $0.kind == .passiveDecompression }
        let recoveryOpen = decompression.recoveryWindowOpen

        var score = 0.52
        if deepFocus { score -= 0.22 }
        if interruptionSensitive { score -= 0.18 }
        if fragmented { score -= 0.12 }
        if decompression.inDecompression { score -= 0.15 }
        if passive { score -= 0.08 }
        if recoveryOpen { score += 0.1 }
        if behavioral.orchestration.signals.contains(where: { $0.kind == .returnAfterAbsence }) {
            score += 0.08
        }

        return NoxInterventionReceptiveness(
            score: min(1, max(0, score)),
            interruptionSensitive: interruptionSensitive,
            deepFocusStable: deepFocus,
            recoveryOpen: recoveryOpen,
            fragmented: fragmented,
            passiveDecompression: passive
        )
    }
}
