import Foundation

/// Deterministically extracts typed semantic memories from compressed horizons.
enum NoxTypedMemoryExtractor {

    static func extract(
        from snapshot: NoxMemoryRollupSnapshot,
        existingIds: Set<String> = []
    ) -> [NoxTypedMemoryEntity] {
        guard snapshot.level == .daily || snapshot.level == .weekly else { return [] }

        var entities: [NoxTypedMemoryEntity] = []
        let facts = snapshot.facts
        let now = Date()

        if let ai = detectAIWorkflow(facts) {
            entities.append(makeEntity(
                kind: .aiWorkflow,
                title: ai.title,
                summary: ai.summary,
                signals: ai.signals,
                snapshot: snapshot,
                now: now,
                existingIds: existingIds
            ))
        }

        if let travel = detectTravelPlanning(facts) {
            entities.append(makeEntity(
                kind: .travelPlanning,
                title: travel.title,
                summary: travel.summary,
                signals: travel.signals,
                snapshot: snapshot,
                now: now,
                existingIds: existingIds
            ))
        }

        if let project = detectProjectArc(facts, level: snapshot.level) {
            entities.append(makeEntity(
                kind: .projectArc,
                title: project.title,
                summary: project.summary,
                signals: project.signals,
                snapshot: snapshot,
                now: now,
                existingIds: existingIds
            ))
        }

        if let rhythm = detectBehavioralRhythm(facts) {
            entities.append(makeEntity(
                kind: .behavioralRhythm,
                title: rhythm.title,
                summary: rhythm.summary,
                signals: rhythm.signals,
                snapshot: snapshot,
                now: now,
                existingIds: existingIds
            ))
        }

        return entities
    }

    // MARK: - Detectors

    private struct Detection {
        let title: String
        let summary: String
        let signals: [NoxExplainableSignal]
    }

    private static func detectAIWorkflow(_ facts: NoxRollupFacts) -> Detection? {
        let aiSignals = facts.topSemanticTitles.filter {
            $0.lowercased().contains("ai") || $0.lowercased().contains("chatgpt")
        }
        let devApps = facts.dominantApps.filter {
            $0.name.lowercased().contains("cursor") || $0.name.lowercased().contains("xcode")
        }
        guard !aiSignals.isEmpty, !devApps.isEmpty else { return nil }
        return Detection(
            title: "AI-assisted workflow",
            summary: "Recurring AI-orchestrated development loops across the period.",
            signals: [
                NoxExplainableSignal(signal: "semantic", detail: aiSignals.joined(separator: ", ")),
                NoxExplainableSignal(signal: "apps", detail: devApps.map(\.name).joined(separator: ", "))
            ]
        )
    }

    private static func detectTravelPlanning(_ facts: NoxRollupFacts) -> Detection? {
        let travelHints = facts.recurringContexts + facts.topSemanticTitles
        guard travelHints.contains(where: { $0.lowercased().contains("travel") }) else { return nil }
        return Detection(
            title: "Travel planning period",
            summary: "Travel-related browsing and comparison activity.",
            signals: [NoxExplainableSignal(signal: "context", detail: "travel-related contexts detected")]
        )
    }

    private static func detectProjectArc(_ facts: NoxRollupFacts, level: NoxMemoryCompressionLevel) -> Detection? {
        guard let top = facts.dominantApps.first else { return nil }
        let threshold = level == .weekly ? 3_600_000 : 1_800_000
        guard top.durationMs >= threshold else { return nil }
        return Detection(
            title: "Project focus: \(top.name)",
            summary: "Sustained project arc centered on \(top.name).",
            signals: [
                NoxExplainableSignal(
                    signal: "dominance",
                    detail: "\(top.durationMs / 60_000)m in \(top.name)",
                    weight: 0.9
                )
            ]
        )
    }

    private static func detectBehavioralRhythm(_ facts: NoxRollupFacts) -> Detection? {
        guard facts.fragmentedMs > facts.focusedMs, facts.appSwitchCount >= 8 else { return nil }
        return Detection(
            title: "Fragmented work rhythm",
            summary: "Frequent context switching with shorter focus windows.",
            signals: [
                NoxExplainableSignal(signal: "switching", detail: "\(facts.appSwitchCount) app transitions"),
                NoxExplainableSignal(signal: "fragmentation", detail: "fragmented time exceeded focused time")
            ]
        )
    }

    private static func makeEntity(
        kind: NoxTypedMemoryKind,
        title: String,
        summary: String,
        signals: [NoxExplainableSignal],
        snapshot: NoxMemoryRollupSnapshot,
        now: Date,
        existingIds: Set<String>
    ) -> NoxTypedMemoryEntity {
        let id = "typed-\(kind.rawValue)-\(snapshot.id)"
        let resolvedId = existingIds.contains(id) ? "\(id)-\(Int(now.timeIntervalSince1970))" : id
        return NoxTypedMemoryEntity(
            id: resolvedId,
            kind: kind,
            title: title,
            summary: summary,
            periodStart: snapshot.periodStart,
            periodEnd: snapshot.periodEnd,
            confidence: min(1.0, 0.5 + Double(signals.count) * 0.1),
            supportingSignals: signals,
            metadata: ["source_rollup": snapshot.id],
            sensitivityLevel: .normal,
            sourceHorizon: snapshot.level,
            createdAt: now,
            updatedAt: now
        )
    }
}
