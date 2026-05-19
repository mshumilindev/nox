import Foundation

nonisolated enum NoxBehavioralDriftEngine {

    static func detect(
        recentDailyDensity: [Double],
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        signatures: [NoxBehavioralSignature],
        at date: Date = Date()
    ) -> NoxBehavioralDriftInsight? {
        if recentDailyDensity.count >= 6 {
            let recent = Array(recentDailyDensity.suffix(3))
            let prior = Array(recentDailyDensity.dropLast(3).suffix(3))
            if !prior.isEmpty {
                let recentAvg = recent.reduce(0, +) / Double(recent.count)
                let priorAvg = prior.reduce(0, +) / Double(prior.count)
                if priorAvg >= 0.5, recentAvg <= 0.25 {
                    return drift(
                        kind: .prolongedQuiet,
                        label: "Quieter than usual",
                        detail: "Recent days have been calmer than the prior stretch.",
                        confidence: 0.58
                    )
                }
                if priorAvg <= 0.35, recentAvg >= 0.65 {
                    return drift(
                        kind: .sustainedDeviation,
                        label: "Denser than usual",
                        detail: "Activity density has risen compared with earlier days.",
                        confidence: 0.56
                    )
                }
            }
        }

        if signatures.contains(where: { $0.kind == .instabilityPhase }) {
            return drift(
                kind: .rhythmInstability,
                label: "Less stable rhythms",
                detail: "Recent rhythms have been less stable than usual.",
                confidence: 0.6
            )
        }

        let switches = max(stats.appSwitchCount, focus?.switchCount ?? 0)
        if switches >= 18 {
            return drift(
                kind: .rhythmInstability,
                label: "Unusual switching",
                detail: "Context switching has been higher than a typical day.",
                confidence: 0.57
            )
        }

        if recentDailyDensity.count >= 5,
           recentDailyDensity.suffix(4).allSatisfy({ $0 < 0.2 }),
           stats.totalActiveMs < 30 * 60_000 {
            return drift(
                kind: .cadenceCollapse,
                label: "Quiet cadence stretch",
                detail: "Established cadence has been quiet for several days.",
                confidence: 0.54
            )
        }

        _ = date
        return nil
    }

    private static func drift(
        kind: NoxBehavioralDriftKind,
        label: String,
        detail: String,
        confidence: Double
    ) -> NoxBehavioralDriftInsight {
        NoxBehavioralDriftInsight(
            label: NoxEmotionalSafetyCopy.sanitize(label),
            detail: NoxEmotionalSafetyCopy.sanitize(detail),
            confidence: confidence,
            driftKind: kind
        )
    }
}
