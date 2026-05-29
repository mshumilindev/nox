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

enum NoxCommunicationPressureEngine {

    static func analyze(
        cadence: NoxCommunicationCadenceSnapshot,
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        at date: Date = Date()
    ) -> (signals: [NoxGeneralizedSignal], pressure: [NoxPressureSignal]) {
        var generalized: [NoxGeneralizedSignal] = []
        var pressure: [NoxPressureSignal] = []

        if cadence.communicationMinutes >= 90 || cadence.burstWindows >= 2 {
            generalized.append(generalizedSignal(
                id: "comm-sustained-load",
                label: "Sustained communication load",
                confidence: 0.74,
                at: date
            ))
        }

        if cadence.responseHeavyScore >= 0.65 {
            generalized.append(generalizedSignal(
                id: "comm-response-window",
                label: "Response-heavy window",
                confidence: cadence.responseHeavyScore,
                at: date
            ))
        }

        if cadence.quietMinutes >= 120 && cadence.communicationMinutes > 0 {
            generalized.append(generalizedSignal(
                id: "comm-quiet-period",
                label: "Quiet communication period",
                confidence: 0.66,
                at: date
            ))
        }

        if cadence.burstWindows >= 2 && (focus?.switchCount ?? stats.appSwitchCount) >= 8 {
            generalized.append(generalizedSignal(
                id: "comm-fragmented-attention",
                label: "Fragmented attention period",
                confidence: 0.7,
                at: date
            ))
        }

        if cadence.communicationMinutes >= 60 && cadence.burstWindows >= 1 {
            pressure.append(pressureSignal(
                id: "comm-inbound-pressure",
                label: "Inbound communication pressure is elevated.",
                level: .elevated,
                confidence: 0.75,
                at: date
            ))
        } else if cadence.communicationMinutes >= 25 {
            pressure.append(pressureSignal(
                id: "comm-moderate-pressure",
                label: "Moderate communication cadence today.",
                level: .moderate,
                confidence: 0.62,
                at: date
            ))
        }

        if cadence.quietMinutes >= 180 {
            pressure.append(pressureSignal(
                id: "comm-low-pressure",
                label: "Communication has been unusually quiet.",
                level: .low,
                confidence: 0.64,
                at: date
            ))
        }

        return (generalized, pressure)
    }

    private static func generalizedSignal(
        id: String,
        label: String,
        confidence: Double,
        at date: Date
    ) -> NoxGeneralizedSignal {
        NoxGeneralizedSignal(
            id: id,
            kind: .communication,
            label: label,
            confidence: confidence,
            observedAt: date
        )
    }

    private static func pressureSignal(
        id: String,
        label: String,
        level: NoxPressureLevel,
        confidence: Double,
        at date: Date
    ) -> NoxPressureSignal {
        NoxPressureSignal(
            id: id,
            kind: .communication,
            label: label,
            level: level,
            confidence: confidence,
            observedAt: date
        )
    }
}
