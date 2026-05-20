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

enum NoxRhythmDetector {

    static func patterns(
        stats: NoxMemoryDayStats,
        workMinutes: Int,
        focus: NoxFocusAnalysis?,
        calendarSignals: [NoxGeneralizedSignal],
        communicationCadence: NoxCommunicationCadenceSnapshot,
        recentDailyDensity: [Double],
        at date: Date = Date()
    ) -> [NoxCadencePattern] {
        var patterns: [NoxCadencePattern] = []
        let switches = max(stats.appSwitchCount, focus?.switchCount ?? 0)

        if workMinutes >= 180 {
            patterns.append(pattern(
                id: "rhythm-work-heavy",
                label: "Work-heavy period",
                confidence: 0.72,
                horizonDays: 1
            ))
        }

        if switches <= 4 && workMinutes < 60 {
            patterns.append(pattern(
                id: "rhythm-recovery",
                label: "Recovery-oriented period",
                confidence: 0.65,
                horizonDays: 1
            ))
        }

        if focus?.kind == .deepWork {
            patterns.append(pattern(
                id: "rhythm-deep-focus-era",
                label: "Sustained deep-focus era",
                confidence: 0.78,
                horizonDays: 1
            ))
        }

        if calendarSignals.contains(where: { $0.id == "calendar-travel-like" }) {
            patterns.append(pattern(
                id: "rhythm-travel-cadence",
                label: "Travel cadence",
                confidence: 0.7,
                horizonDays: 3
            ))
        }

        if switches >= 12 || focus?.kind == .fragmented {
            patterns.append(pattern(
                id: "rhythm-context-instability",
                label: "Context instability",
                confidence: 0.74,
                horizonDays: 1
            ))
        }

        if oscillation(in: recentDailyDensity) {
            patterns.append(pattern(
                id: "rhythm-overload-inactivity",
                label: "Work and recovery oscillation",
                confidence: 0.68,
                horizonDays: 7
            ))
        }

        if communicationCadence.burstWindows >= 2 && workMinutes >= 120 {
            patterns.append(pattern(
                id: "rhythm-irregular",
                label: "Irregular work and communication rhythm",
                confidence: 0.66,
                horizonDays: 3
            ))
        }

        if let weekday = Calendar.current.dateComponents([.weekday], from: date).weekday,
           weekday == 4,
           calendarSignals.contains(where: { $0.id == "calendar-coordination" }) {
            patterns.append(pattern(
                id: "rhythm-coordination-wednesday",
                label: "Recurring coordination-heavy rhythm",
                confidence: 0.6,
                horizonDays: 14
            ))
        }

        return patterns
    }

    private static func oscillation(in densities: [Double]) -> Bool {
        guard densities.count >= 4 else { return false }
        let highs = densities.filter { $0 >= 0.65 }.count
        let lows = densities.filter { $0 <= 0.35 }.count
        return highs >= 2 && lows >= 2
    }

    private static func pattern(
        id: String,
        label: String,
        confidence: Double,
        horizonDays: Int
    ) -> NoxCadencePattern {
        NoxCadencePattern(
            id: id,
            label: label,
            confidence: confidence,
            horizonDays: horizonDays
        )
    }
}
