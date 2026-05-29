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

nonisolated enum NoxSystemContradictionContextBuilder {

    static func build(
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        threads: [NoxContinuityThread],
        utility: NoxAmbientUtilitySnapshot,
        connectorSnapshot: NoxConnectorContinuitySnapshot,
        observationContinuitySeconds: TimeInterval,
        isUserIdle: Bool,
        previousDominantCategory: NoxActivityCategory?
    ) -> NoxSystemContradictionContext {
        let returning = connectorSnapshot.transitions.contains {
            $0.kind == .returningAfterAbsence && $0.confidence >= 0.65
        }
        return NoxSystemContradictionContext(
            stats: stats,
            focus: focus,
            threads: threads,
            receptiveness: utility.receptiveness,
            decompression: utility.decompression,
            recoveryWindow: utility.recoveryWindow,
            preferSilence: utility.preferSilence,
            interruptionCost: utility.calibration.interruptionCost,
            observationContinuitySeconds: observationContinuitySeconds,
            isUserIdle: isUserIdle,
            dominantCategory: stats.dominantCategory,
            returningAfterAbsence: returning,
            previousDominantCategory: previousDominantCategory
        )
    }
}
