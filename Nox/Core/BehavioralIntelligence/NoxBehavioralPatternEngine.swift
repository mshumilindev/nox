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
                label: "Late-night work cycle",
                detail: "Evening work has appeared again — observational, not prescriptive.",
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
                label: "Overload–recovery oscillation",
                detail: "Active stretches and quieter stretches have been alternating.",
                confidence: 0.67,
                horizonDays: 14,
                evidence: ["density_oscillation"]
            ))
        }

        if commMs >= 90 * 60_000 || connectorCadence.contains(where: { $0.id.contains("coordination") }) {
            signatures.append(sig(
                id: "pattern-coordination-week",
                kind: .coordinationHeavyWeek,
                label: "Coordination-heavy stretch",
                detail: "Communication and scheduling density may be shaping the week.",
                confidence: 0.61,
                horizonDays: 7,
                evidence: ["communication_load"]
            ))
        }

        if focus?.kind == .deepWork || connectorCadence.contains(where: { $0.id == "rhythm-deep-focus-era" }) {
            signatures.append(sig(
                id: "pattern-deep-focus-streak",
                kind: .deepFocusStreak,
                label: "Deep-focus streak",
                detail: "Sustained focus blocks have been forming locally.",
                confidence: 0.7,
                horizonDays: 3,
                evidence: ["deep_focus"]
            ))
        }

        if switches >= 12 || focus?.kind == .fragmented {
            signatures.append(sig(
                id: "pattern-fragmented-context",
                kind: .fragmentedContext,
                label: "Fragmented context period",
                detail: "Attention has been switching often between contexts.",
                confidence: 0.72,
                horizonDays: 2,
                evidence: ["switch_count:\(switches)"]
            ))
        }

        if creativeMs >= 60 * 60_000 {
            signatures.append(sig(
                id: "pattern-creative-exploration",
                kind: .creativeExploration,
                label: "Creative exploration phase",
                detail: "Creative tools have had sustained presence recently.",
                confidence: 0.58,
                horizonDays: 14,
                evidence: ["creative_duration"]
            ))
        }

        if passiveMs >= stats.totalActiveMs / 2, stats.totalActiveMs > 0 {
            signatures.append(sig(
                id: "pattern-passive-decompression",
                kind: .passiveDecompression,
                label: "Passive decompression loop",
                detail: "Passive viewing or listening has dominated recent activity.",
                confidence: 0.6,
                horizonDays: 3,
                evidence: ["passive_share"]
            ))
        }

        if instabilityFromRollups(weeklyRollups) {
            signatures.append(sig(
                id: "pattern-instability-phase",
                kind: .instabilityPhase,
                label: "Instability phase",
                detail: "Weekly memory suggests unusually scattered continuity.",
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
