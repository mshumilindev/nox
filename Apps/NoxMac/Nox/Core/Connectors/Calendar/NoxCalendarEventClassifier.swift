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

enum NoxCalendarEventClassifier {

    static func generalizedSignals(
        profile: NoxCalendarDayProfile,
        at date: Date = Date()
    ) -> [NoxGeneralizedSignal] {
        guard profile.eventCount > 0 else { return [] }
        var signals: [NoxGeneralizedSignal] = []

        if profile.eventCount >= 5 || profile.meetingMinutes >= 240 {
            signals.append(signal(
                id: "calendar-dense",
                label: "Unusually dense meeting cadence",
                confidence: min(0.92, 0.55 + Double(profile.eventCount) * 0.06),
                at: date
            ))
        }

        if profile.eventCount >= 4 && profile.meetingMinutes >= 150 {
            signals.append(signal(
                id: "calendar-coordination",
                label: "High coordination day",
                confidence: 0.78,
                at: date
            ))
        }

        if profile.afternoonEventCount >= 3 && profile.backToBackBlocks >= 2 {
            signals.append(signal(
                id: "calendar-fragmented-afternoon",
                label: "Fragmented afternoon",
                confidence: 0.74,
                at: date
            ))
        }

        if profile.longestGapMinutes >= 120 && profile.eventCount >= 2 {
            signals.append(signal(
                id: "calendar-focus-window",
                label: "Extended uninterrupted focus window",
                confidence: 0.7,
                at: date
            ))
        }

        if profile.longestGapMinutes >= 75 {
            signals.append(signal(
                id: "calendar-recovery-gap",
                label: "Recovery gap between commitments",
                confidence: 0.66,
                at: date
            ))
        }

        if profile.eveningEventCount >= 2 {
            signals.append(signal(
                id: "calendar-late-evening",
                label: "Late-evening meeting pattern",
                confidence: 0.72,
                at: date
            ))
        }

        if profile.hasTravelLikeStructure {
            signals.append(signal(
                id: "calendar-travel-like",
                label: "Travel-like calendar structure",
                confidence: 0.68,
                at: date
            ))
        }

        return signals
    }

    private static func signal(
        id: String,
        label: String,
        confidence: Double,
        at date: Date
    ) -> NoxGeneralizedSignal {
        NoxGeneralizedSignal(
            id: id,
            kind: .calendar,
            label: label,
            confidence: confidence,
            observedAt: date
        )
    }
}
