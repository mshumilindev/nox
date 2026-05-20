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

nonisolated enum NoxContextualExpectationEngine {

    static func build(
        signatures: [NoxBehavioralSignature],
        cadencePatterns: [NoxCadencePattern],
        recentDailyDensity: [Double],
        stats: NoxMemoryDayStats,
        at date: Date = Date()
    ) -> NoxExpectedRhythmModel? {
        var work: [NoxExpectedRhythmWindow] = []
        var recovery: [NoxExpectedRhythmWindow] = []
        var transitions: [String] = []
        var continuity: [String] = []
        var confidenceSum = 0.0
        var parts = 0

        if signatures.contains(where: { $0.kind == .lateNightWorkCycle }) {
            work.append(window("Evening work window", start: 20, end: 24, confidence: 0.58))
            parts += 1
            confidenceSum += 0.58
        }

        if signatures.contains(where: { $0.kind == .overloadRecoveryOscillation }) {
            recovery.append(window("Midday recovery window", start: 12, end: 15, confidence: 0.55))
            transitions.append("Alternation between dense and quiet stretches")
            parts += 1
            confidenceSum += 0.55
        }

        if cadencePatterns.contains(where: { $0.id == "rhythm-coordination-wednesday" }) {
            continuity.append("Coordination may cluster mid-week")
            parts += 1
            confidenceSum += 0.6
        }

        if signatures.contains(where: { $0.kind == .deepFocusStreak }) {
            work.append(window("Morning focus window", start: 9, end: 12, confidence: 0.62))
            continuity.append("Deep focus may return in similar windows")
            parts += 1
            confidenceSum += 0.62
        }

        if recentDailyDensity.count >= 5 {
            let avg = recentDailyDensity.reduce(0, +) / Double(recentDailyDensity.count)
            if avg >= 0.55 {
                continuity.append("Activity density has been elevated across recent days")
                parts += 1
                confidenceSum += 0.54
            }
        }

        guard parts > 0 else { return nil }

        let confidence = min(0.78, confidenceSum / Double(parts))
        guard confidence >= NoxPatternConfidenceModel.minimumDisplay else { return nil }

        return NoxExpectedRhythmModel(
            likelyWorkWindows: work,
            likelyRecoveryWindows: recovery,
            expectedTransitions: transitions.map { NoxEmotionalSafetyCopy.sanitize($0) },
            continuityExpectations: continuity.map { NoxEmotionalSafetyCopy.sanitize($0) },
            confidence: confidence
        )
    }

    private static func window(
        _ label: String,
        start: Int,
        end: Int,
        confidence: Double
    ) -> NoxExpectedRhythmWindow {
        NoxExpectedRhythmWindow(label: label, startHour: start, endHour: end, confidence: confidence)
    }
}
