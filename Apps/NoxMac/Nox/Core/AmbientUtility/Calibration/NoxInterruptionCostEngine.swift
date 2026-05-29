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

nonisolated enum NoxInterruptionCostEngine {

    static func estimate(
        focus: NoxFocusAnalysis?,
        stats: NoxMemoryDayStats,
        receptiveness: NoxInterventionReceptiveness,
        decompression: NoxDecompressionState,
        behavioral: NoxBehavioralIntelligenceSnapshot,
        calmness: NoxAdaptiveCalmnessProfile
    ) -> Double {
        var cost = 0.32

        if receptiveness.deepFocusStable { cost += 0.35 }
        if receptiveness.interruptionSensitive { cost += 0.22 }
        if stats.appSwitchCount >= 14 { cost += 0.12 }
        if decompression.inDecompression { cost += 0.18 }
        if decompression.passiveCollapseLoop { cost += 0.15 }
        if behavioral.orchestration.signals.contains(where: { $0.kind == .highInterruptionSensitivity }) {
            cost += 0.14
        }
        if focus?.kind == .deepWork { cost += 0.2 }
        if calmness.continuitySurfacingDepth < 0.5 { cost += 0.08 }

        return min(1, max(0, cost))
    }
}
