import Foundation

enum NoxCalendarPressureAnalyzer {

    static func pressureSignals(
        profile: NoxCalendarDayProfile,
        at date: Date = Date()
    ) -> [NoxPressureSignal] {
        guard profile.eventCount > 0 else { return [] }
        var signals: [NoxPressureSignal] = []

        let densityScore = Double(profile.meetingMinutes) / 360.0 + Double(profile.eventCount) * 0.15
        if densityScore >= 1.4 {
            signals.append(pressure(
                id: "calendar-pressure-elevated",
                label: "Calendar load is elevated today.",
                level: .elevated,
                confidence: min(0.9, densityScore / 2.0),
                at: date
            ))
        } else if densityScore >= 0.85 {
            signals.append(pressure(
                id: "calendar-pressure-moderate",
                label: "Moderate coordination pressure from the calendar.",
                level: .moderate,
                confidence: 0.7,
                at: date
            ))
        }

        if profile.backToBackBlocks >= 3 {
            signals.append(pressure(
                id: "calendar-switch-load",
                label: "Context switching load is high between commitments.",
                level: .elevated,
                confidence: 0.76,
                at: date
            ))
        }

        if profile.longestGapMinutes < 30 && profile.eventCount >= 3 {
            signals.append(pressure(
                id: "calendar-fragmented-day",
                label: "The day is unusually fragmented.",
                level: .moderate,
                confidence: 0.71,
                at: date
            ))
        }

        return signals
    }

    private static func pressure(
        id: String,
        label: String,
        level: NoxPressureLevel,
        confidence: Double,
        at date: Date
    ) -> NoxPressureSignal {
        NoxPressureSignal(
            id: id,
            kind: .calendar,
            label: label,
            level: level,
            confidence: confidence,
            observedAt: date
        )
    }
}
