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

nonisolated enum NoxBehavioralConsistencyModel {

    struct Signature: Equatable, Sendable {
        let stabilizesRhythm: Bool
        let fragmentsEasily: Bool
        let recoversAfterOverload: Bool
        let passiveDecompressionTendency: Bool
        let confidence: Double
    }

    static func infer(
        behavioral: NoxBehavioralIntelligenceSnapshot,
        focus: NoxFocusAnalysis?,
        calibration: NoxAmbientUtilityCalibration
    ) -> Signature {
        let signatures = behavioral.signatures.filter(\.isGated)
        let stabilizes = signatures.contains {
            $0.kind == .deepFocusStreak || $0.kind == .coordinationHeavyWeek
        }
        let fragments = signatures.contains { $0.kind == .fragmentedContext }
            || (focus?.switchCount ?? 0) > 10
        let recovers = signatures.contains { $0.kind == .overloadRecoveryOscillation }
            || calibration.recoveryQuality.kind == .restorativeContinuity
        let passive = calibration.recoveryQuality.kind == .passiveCollapse
            || signatures.contains { $0.kind == .passiveDecompression }

        let confidence = min(1, Double(signatures.count) * 0.18 + 0.35)
        return Signature(
            stabilizesRhythm: stabilizes,
            fragmentsEasily: fragments,
            recoversAfterOverload: recovers,
            passiveDecompressionTendency: passive,
            confidence: confidence
        )
    }
}
