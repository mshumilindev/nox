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

nonisolated enum NoxDecompressionMaturityEngine {

    static func evaluate(
        base: NoxDecompressionState,
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        behavioral: NoxBehavioralIntelligenceSnapshot,
        recovery: NoxRecoveryWindowModel
    ) -> NoxRecoveryQualityModel {
        let fragmented = focus?.kind == .fragmented || stats.fragmentedMs > stats.focusedMs
        let overload = behavioral.orchestration.signals.contains { $0.kind == .overloadRiskElevation }

        if base.overloadAfterCoordination && base.passiveCollapseLoop {
            return quality(
                .overloadLoop,
                suppress: true,
                silence: true,
                gentle: false,
                confidence: 0.65
            )
        }

        if base.passiveCollapseLoop && fragmented {
            return quality(
                .fragmentedEscapism,
                suppress: true,
                silence: true,
                gentle: false,
                confidence: 0.62
            )
        }

        if base.passiveCollapseLoop {
            return quality(
                .passiveCollapse,
                suppress: true,
                silence: true,
                gentle: false,
                confidence: 0.6
            )
        }

        if recovery.isOpen && !fragmented {
            return quality(
                .restorativeContinuity,
                suppress: false,
                silence: false,
                gentle: true,
                confidence: 0.58
            )
        }

        if recovery.isOpen {
            return quality(
                .healthyRecovery,
                suppress: false,
                silence: overload,
                gentle: true,
                confidence: 0.55
            )
        }

        return quality(.neutral, suppress: false, silence: base.inDecompression, gentle: true, confidence: 0.45)
    }

    private static func quality(
        _ kind: NoxDecompressionQualityKind,
        suppress: Bool,
        silence: Bool,
        gentle: Bool,
        confidence: Double
    ) -> NoxRecoveryQualityModel {
        NoxRecoveryQualityModel(
            kind: kind,
            suppressResurfacing: suppress,
            preferSilence: silence,
            allowGentleContinuity: gentle,
            confidence: confidence
        )
    }
}
