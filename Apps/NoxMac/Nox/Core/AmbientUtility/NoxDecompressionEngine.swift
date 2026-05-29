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

nonisolated enum NoxDecompressionEngine {

    static func evaluate(
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        behavioral: NoxBehavioralIntelligenceSnapshot,
        connectorSnapshot: NoxConnectorContinuitySnapshot
    ) -> (state: NoxDecompressionState, recovery: NoxRecoveryWindowModel) {
        let passive = behavioral.signatures.contains { $0.kind == .passiveDecompression }
        let overload = !connectorSnapshot.overloadSignals.isEmpty
            || behavioral.orchestration.signals.contains { $0.kind == .overloadRiskElevation }
        let fragmented = focus?.kind == .fragmented || stats.appSwitchCount >= 12
        let coordination = behavioral.signatures.contains { $0.kind == .coordinationHeavyWeek }

        let passiveLoop = passive && stats.totalActiveMs > 0
            && stats.focusedMs < stats.totalActiveMs / 3
        let overloadAfterCoordination = overload && coordination

        let recoveryOpen = behavioral.orchestration.signals.contains {
            $0.kind == .recoveryOpportunityWindow && $0.level >= 0.58
        } || connectorSnapshot.cadencePatterns.contains { $0.id == "rhythm-recovery" }

        let inDecompression = passiveLoop || (overloadAfterCoordination && fragmented)

        let state = NoxDecompressionState(
            inDecompression: inDecompression,
            recoveryWindowOpen: recoveryOpen,
            passiveCollapseLoop: passiveLoop,
            overloadAfterCoordination: overloadAfterCoordination,
            confidence: inDecompression ? 0.62 : (recoveryOpen ? 0.55 : 0.4)
        )

        let recovery = NoxRecoveryWindowModel(
            isOpen: recoveryOpen && !fragmented,
            label: recoveryOpen ? "Quieter stretch" : "",
            detail: recoveryOpen
                ? "Activity density has eased — Nox may stay quieter for a while."
                : "",
            confidence: recoveryOpen ? 0.58 : 0.35
        )

        return (state, recovery)
    }
}
