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

nonisolated enum NoxAmbientSilenceEngine {

    static func shouldPreferSilence(
        receptiveness: NoxInterventionReceptiveness,
        decompression: NoxDecompressionState,
        calmness: NoxAdaptiveCalmnessProfile,
        behavioral: NoxBehavioralIntelligenceSnapshot
    ) -> Bool {
        if calmness.preferSilence { return true }
        if decompression.inDecompression { return true }
        if receptiveness.deepFocusStable && receptiveness.interruptionSensitive { return true }
        if receptiveness.fragmented && receptiveness.score < 0.42 { return true }
        if behavioral.orchestration.signals.contains(where: {
            $0.kind == .highInterruptionSensitivity && $0.level >= 0.72
        }) {
            return true
        }
        return false
    }
}
