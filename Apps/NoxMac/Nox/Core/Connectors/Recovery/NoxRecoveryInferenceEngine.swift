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

enum NoxRecoveryInferenceEngine {

    static func overloadSignals(
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        calendarProfile: NoxCalendarDayProfile,
        pressureSignals: [NoxPressureSignal],
        at date: Date = Date()
    ) -> [NoxOverloadSignal] {
        var signals: [NoxOverloadSignal] = []
        let switches = max(stats.appSwitchCount, focus?.switchCount ?? 0)

        if pressureSignals.contains(where: { $0.level == .elevated }) && switches >= 10 {
            signals.append(signal(
                id: "overload-cognitive-pressure",
                label: "Recent activity has been unusually dense.",
                confidence: 0.72,
                at: date
            ))
        }

        if calendarProfile.eventCount >= 4 && calendarProfile.longestGapMinutes < 45 {
            signals.append(signal(
                id: "overload-recovery-spacing",
                label: "Recovery spacing between commitments looks thin.",
                confidence: 0.68,
                at: date
            ))
        }

        if focus?.kind == .fragmented || stats.fragmentedMs >= 45 * 60_000 {
            signals.append(signal(
                id: "overload-fragmentation",
                label: "Attention has been unusually fragmented.",
                confidence: 0.7,
                at: date
            ))
        }

        if switches >= 14 {
            signals.append(signal(
                id: "overload-switching",
                label: "Context switching has been high.",
                confidence: 0.74,
                at: date
            ))
        }

        if focus?.kind == .deepWork,
           focus?.uninterruptedMs ?? 0 >= 90 * 60_000,
           calendarProfile.longestGapMinutes < 20 {
            signals.append(signal(
                id: "overload-long-effort",
                label: "A long uninterrupted effort stretch stands out.",
                confidence: 0.66,
                at: date
            ))
        }

        return signals
            .sorted { $0.confidence > $1.confidence }
            .prefix(4)
            .map { $0 }
    }

    private static func signal(
        id: String,
        label: String,
        confidence: Double,
        at date: Date
    ) -> NoxOverloadSignal {
        NoxOverloadSignal(
            id: id,
            label: label,
            confidence: confidence,
            observedAt: date
        )
    }
}
