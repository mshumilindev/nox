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

nonisolated enum NoxTemporalRhythmEngine {

    static func infer(
        weeklyRollups: [NoxMemoryRollupSnapshot],
        monthlyRollups: [NoxMemoryRollupSnapshot],
        signatures: [NoxBehavioralSignature],
        recentDailyDensity: [Double]
    ) -> [NoxTemporalRhythmInsight] {
        var insights: [NoxTemporalRhythmInsight] = []

        if let week = weeklyRollups.last {
            if week.facts.focusedMs > week.facts.fragmentedMs {
                insights.append(insight(
                    id: "rhythm-weekly-focus",
                    label: "Weekly focus rhythm",
                    detail: "This week leaned toward sustained focus over fragmentation.",
                    horizon: .weekly,
                    confidence: 0.62
                ))
            } else if week.facts.fragmentedMs > week.facts.focusedMs {
                insights.append(insight(
                    id: "rhythm-weekly-fragmented",
                    label: "Unstable weekly rhythm",
                    detail: "Fragmented stretches outweighed focus this week.",
                    horizon: .weekly,
                    confidence: 0.6
                ))
            }
        }

        if monthlyRollups.count >= 2 {
            let recent = monthlyRollups.suffix(2)
            let focusTrend = recent.map(\.facts.focusedMs)
            if focusTrend.count == 2, focusTrend[1] > Int(Double(focusTrend[0]) * 1.25) {
                insights.append(insight(
                    id: "rhythm-monthly-focus-rise",
                    label: "Monthly focus shift",
                    detail: "Focus time has been rising across recent months.",
                    horizon: .monthly,
                    confidence: 0.57
                ))
            }
        }

        if signatures.contains(where: { $0.kind == .overloadRecoveryOscillation }) {
            insights.append(insight(
                id: "rhythm-seasonal-oscillation",
                label: "Oscillating cadence",
                detail: "Work and recovery have been trading places across days.",
                horizon: .seasonal,
                confidence: 0.55
            ))
        }

        if recentDailyDensity.count >= 7 {
            let variance = densityVariance(recentDailyDensity)
            if variance > 0.08 {
                insights.append(insight(
                    id: "rhythm-density-swing",
                    label: "Density swings",
                    detail: "Activity density has been uneven day to day.",
                    horizon: .weekly,
                    confidence: 0.54
                ))
            }
        }

        return NoxPatternConfidenceModel.gate(insights) { $0.confidence }
    }

    private static func densityVariance(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        return values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
    }

    private static func insight(
        id: String,
        label: String,
        detail: String,
        horizon: NoxTemporalRhythmHorizon,
        confidence: Double
    ) -> NoxTemporalRhythmInsight {
        NoxTemporalRhythmInsight(
            id: id,
            label: label,
            detail: NoxEmotionalSafetyCopy.sanitize(detail),
            horizon: horizon,
            confidence: confidence
        )
    }
}
