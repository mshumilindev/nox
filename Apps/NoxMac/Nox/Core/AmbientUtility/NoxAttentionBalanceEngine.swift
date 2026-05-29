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

nonisolated enum NoxAttentionBalanceEngine {

    static func insight(
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        threads: [NoxContinuityThread],
        structural: [NoxStructuralContinuityWeight]
    ) -> NoxAttentionBalanceInsight? {
        let fragmented = focus?.kind == .fragmented || stats.fragmentedMs > stats.focusedMs
        let neglected = threads.filter { $0.decayState == .fading && $0.recurrenceStrength >= 0.4 }
        let overConcentrated = stats.longestFocusBlockMs >= 3 * 3600_000 && stats.appSwitchCount <= 4

        if fragmented, stats.appSwitchCount >= 14 {
            return NoxAttentionBalanceInsight(
                label: "Scattered stretch",
                detail: "Attention has been splitting often — continuity stays loose.",
                confidence: 0.58
            )
        }

        if let neglected = neglected.first {
            let name = neglected.title.replacingOccurrences(of: " continuity", with: "")
            return NoxAttentionBalanceInsight(
                label: "Fading through-line",
                detail: "\(name) has been quieter while other contexts took the foreground.",
                confidence: 0.54
            )
        }

        if overConcentrated {
            return NoxAttentionBalanceInsight(
                label: "Narrow stretch",
                detail: "A single context has held most of the day — other threads are in the background.",
                confidence: 0.52
            )
        }

        if structural.contains(where: { $0.kind == .attentionSink }) {
            return NoxAttentionBalanceInsight(
                label: "Light fragmentation",
                detail: "Switching has outweighed sustained stretches recently.",
                confidence: 0.53
            )
        }

        return nil
    }
}
