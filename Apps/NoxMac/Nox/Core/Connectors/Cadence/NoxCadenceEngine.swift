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

enum NoxCadenceEngine {

    static func build(
        stats: NoxMemoryDayStats,
        workMinutes: Int,
        focus: NoxFocusAnalysis?,
        calendarSignals: [NoxGeneralizedSignal],
        communicationCadence: NoxCommunicationCadenceSnapshot,
        storedPatterns: [NoxCadencePattern],
        recentDailyDensity: [Double] = [],
        at date: Date = Date()
    ) -> [NoxCadencePattern] {
        var patterns = NoxRhythmDetector.patterns(
            stats: stats,
            workMinutes: workMinutes,
            focus: focus,
            calendarSignals: calendarSignals,
            communicationCadence: communicationCadence,
            recentDailyDensity: recentDailyDensity,
            at: date
        )

        for stored in storedPatterns where stored.horizonDays >= 7 {
            if !patterns.contains(where: { $0.id == stored.id }) {
                patterns.append(stored)
            }
        }

        return patterns
            .sorted { $0.confidence > $1.confidence }
            .prefix(6)
            .map { $0 }
    }
}

enum NoxCadenceDensity {
    static func score(for stats: NoxMemoryDayStats) -> Double {
        let activeMinutes = Double(stats.totalActiveMs) / 60_000.0
        let switches = Double(stats.appSwitchCount)
        return min(1.0, (activeMinutes / 480.0) + (switches / 24.0))
    }
}
