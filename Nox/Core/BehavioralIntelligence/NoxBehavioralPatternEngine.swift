import Foundation

nonisolated enum NoxBehavioralPatternEngine {

    static func detect(
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        spans: [NoxActivitySpan],
        connectorCadence: [NoxCadencePattern],
        recentDailyDensity: [Double],
        weeklyRollups: [NoxMemoryRollupSnapshot],
        at date: Date = Date()
    ) -> [NoxBehavioralSignature] {
        var signatures: [NoxBehavioralSignature] = []
        let hour = Calendar.current.component(.hour, from: date)
        let workMinutes = spans.filter(\.category.isWorkLike).reduce(0) { $0 + $1.durationMs / 60_000 }
        let switches = max(stats.appSwitchCount, focus?.switchCount ?? 0)
        let passiveMs = spans.filter { $0.category == .passive || $0.category == .entertainment }
            .reduce(0) { $0 + $1.durationMs }
        let creativeMs = spans.filter { $0.category == .creative }.reduce(0) { $0 + $1.durationMs }
        let commMs = spans.filter { $0.category == .communication }.reduce(0) { $0 + $1.durationMs }

        if hour >= 22, workMinutes >= 45 {
            signatures.append(sig(
                id: "pattern-late-night-work",
                kind: .lateNightWorkCycle,
                label: "Evening work again",
                detail: "Work showed up late in the day again recently.",
                confidence: 0.64,
                horizonDays: 7,
                evidence: ["late_hour", "work_minutes:\(workMinutes)"]
            ))
        }

        if connectorCadence.contains(where: { $0.id == "rhythm-overload-inactivity" })
            || oscillation(in: recentDailyDensity) {
            signatures.append(sig(
                id: "pattern-overload-recovery",
                kind: .overloadRecoveryOscillation,
                label: "Busy days, then quieter ones",
                detail: "Fuller days have been followed by calmer ones.",
                confidence: 0.67,
                horizonDays: 14,
                evidence: ["density_oscillation"]
            ))
        }

        if commMs >= 90 * 60_000 || connectorCadence.contains(where: { $0.id.contains("coordination") }) {
            signatures.append(sig(
                id: "pattern-coordination-week",
                kind: .coordinationHeavyWeek,
                label: "A week with more messages and meetings",
                detail: "Communication and calendar time took more of the week.",
                confidence: 0.61,
                horizonDays: 7,
                evidence: ["communication_load"]
            ))
        }

        if focus?.kind == .deepWork || connectorCadence.contains(where: { $0.id == "rhythm-deep-focus-era" }) {
            signatures.append(sig(
                id: "pattern-deep-focus-streak",
                kind: .deepFocusStreak,
                label: "Longer focus stretches",
                detail: "You stayed in sustained work for longer blocks recently.",
                confidence: 0.7,
                horizonDays: 3,
                evidence: ["deep_focus"]
            ))
        }

        if switches >= 12 || focus?.kind == .fragmented {
            signatures.append(sig(
                id: "pattern-fragmented-context",
                kind: .fragmentedContext,
                label: "Scattered stretches",
                detail: "You moved between several apps and tasks for a while.",
                confidence: 0.72,
                horizonDays: 2,
                evidence: ["switch_count:\(switches)"]
            ))
        }

        if creativeMs >= 60 * 60_000 {
            signatures.append(sig(
                id: "pattern-creative-exploration",
                kind: .creativeExploration,
                label: "Creative work in bursts",
                detail: "Creative apps showed up in repeated sessions recently.",
                confidence: 0.58,
                horizonDays: 14,
                evidence: ["creative_duration"]
            ))
        }

        if passiveMs >= stats.totalActiveMs / 2, stats.totalActiveMs > 0 {
            signatures.append(sig(
                id: "pattern-passive-decompression",
                kind: .passiveDecompression,
                label: "Mostly listening or viewing",
                detail: "Passive viewing or listening took most of recent activity.",
                confidence: 0.6,
                horizonDays: 3,
                evidence: ["passive_share"]
            ))
        }

        if instabilityFromRollups(weeklyRollups) {
            signatures.append(sig(
                id: "pattern-instability-phase",
                kind: .instabilityPhase,
                label: "An unsettled week",
                detail: "Days varied more than your usual week-to-week pattern.",
                confidence: 0.56,
                horizonDays: 21,
                evidence: ["weekly_fragmentation"]
            ))
        }

        return NoxPatternConfidenceModel.gate(signatures) { $0.confidence }
    }

    private static func oscillation(in densities: [Double]) -> Bool {
        guard densities.count >= 4 else { return false }
        let highs = densities.filter { $0 >= 0.65 }.count
        let lows = densities.filter { $0 <= 0.35 }.count
        return highs >= 2 && lows >= 2
    }

    private static func instabilityFromRollups(_ weekly: [NoxMemoryRollupSnapshot]) -> Bool {
        guard let latest = weekly.last else { return false }
        return latest.facts.fragmentedMs > latest.facts.focusedMs && latest.facts.appSwitchCount >= 40
    }

    private static func sig(
        id: String,
        kind: NoxBehavioralPatternKind,
        label: String,
        detail: String,
        confidence: Double,
        horizonDays: Int,
        evidence: [String]
    ) -> NoxBehavioralSignature {
        NoxBehavioralSignature(
            id: id,
            kind: kind,
            label: label,
            detail: NoxEmotionalSafetyCopy.sanitize(detail),
            confidence: confidence,
            horizonDays: horizonDays,
            evidence: evidence
        )
    }
}
