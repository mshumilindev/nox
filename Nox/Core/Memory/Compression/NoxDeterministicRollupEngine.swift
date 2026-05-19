import Foundation

/// Deterministic compression — transforms detail into meaning per horizon.
enum NoxDeterministicRollupEngine {

    static func buildDailyFacts(
        spans: [NoxActivitySpan],
        sessions: [NoxWorkSession],
        semanticSpans: [NoxSemanticMemorySpan],
        interruptions: [NoxInterruption],
        focusBlocks: [NoxFocusBlock]
    ) -> NoxRollupFacts {
        let filteredSpans = spans.filter { !$0.category.excludedFromAnalysis }
        let filteredSessions = sessions.filter {
            !NoxSelfExclusion.isExcluded(bundleId: $0.primaryBundleId, appName: $0.primaryApp)
        }
        let filteredSemantic = semanticSpans.filter { span in
            !span.appNames.contains { NoxSelfExclusion.isExcluded(bundleId: nil, appName: $0) }
                && NoxSensitiveMemoryPolicy.allowsDetailedSemanticLabel(span.sensitivityLevel)
        }

        var facts = NoxRollupFacts()
        facts.totalActiveMs = filteredSpans.reduce(0) { $0 + $1.durationMs }
        facts.focusedMs = focusBlocks
            .filter { $0.kind == .focused || $0.kind == .deepWork }
            .reduce(0) { $0 + $1.durationMs }
        facts.fragmentedMs = focusBlocks
            .filter { $0.kind == .fragmented }
            .reduce(0) { $0 + $1.durationMs }
        facts.sessionCount = filteredSessions.count
        facts.semanticSpanCount = filteredSemantic.count
        facts.interruptionCount = interruptions.count
        facts.appSwitchCount = max(0, filteredSpans.count - 1)

        if let longest = focusBlocks.max(by: { $0.durationMs < $1.durationMs }) {
            facts.longestFocusBlockMs = longest.durationMs
            facts.longestFocusApp = longest.primaryApp
        }

        facts.dominantApps = topApps(from: filteredSpans, limit: 5)
        facts.dominantCategories = topCategories(from: filteredSpans, limit: 4)
        facts.topSemanticTitles = Array(
            filteredSemantic.sorted { $0.durationMs > $1.durationMs }.prefix(5).map(\.title)
        )
        facts.recurringContexts = Array(
            Set(filteredSpans.compactMap(\.contextLabel).filter { !$0.isEmpty }).prefix(6)
        )
        return facts
    }

    static func aggregateFacts(
        level: NoxMemoryCompressionLevel,
        from children: [NoxRollupFacts]
    ) -> NoxRollupFacts {
        guard !children.isEmpty else { return NoxRollupFacts() }

        var merged = NoxRollupFacts()
        merged.childRollupCount = children.count
        merged.totalActiveMs = children.reduce(0) { $0 + $1.totalActiveMs }
        merged.focusedMs = children.reduce(0) { $0 + $1.focusedMs }
        merged.fragmentedMs = children.reduce(0) { $0 + $1.fragmentedMs }
        merged.sessionCount = children.reduce(0) { $0 + $1.sessionCount }
        merged.semanticSpanCount = children.reduce(0) { $0 + $1.semanticSpanCount }
        merged.interruptionCount = children.reduce(0) { $0 + $1.interruptionCount }
        merged.appSwitchCount = children.reduce(0) { $0 + $1.appSwitchCount }

        if let longest = children.max(by: { $0.longestFocusBlockMs < $1.longestFocusBlockMs }) {
            merged.longestFocusBlockMs = longest.longestFocusBlockMs
            merged.longestFocusApp = longest.longestFocusApp
        }

        merged.dominantApps = mergeAppShares(children.flatMap(\.dominantApps), limit: 5)
        merged.dominantCategories = mergeCategoryShares(children.flatMap(\.dominantCategories), limit: 4)
        merged.topSemanticTitles = Array(children.flatMap(\.topSemanticTitles).uniqued().prefix(8))
        merged.recurringContexts = Array(children.flatMap(\.recurringContexts).uniqued().prefix(10))

        return NoxHorizonFactsBuilder.enrich(merged, level: level, children: children)
    }

    static func buildNarrative(facts: NoxRollupFacts, level: NoxMemoryCompressionLevel) -> String {
        NoxLayerNarrativeBuilder.build(facts: facts, level: level)
    }

    static func makeSnapshot(
        level: NoxMemoryCompressionLevel,
        periodStart: Date,
        periodEnd: Date,
        facts: NoxRollupFacts,
        sourceCounts: [String: Int] = [:]
    ) -> NoxMemoryRollupSnapshot {
        let encoder = JSONEncoder()
        let sourceJson: String? = {
            guard let data = try? encoder.encode(sourceCounts) else { return nil }
            return String(data: data, encoding: .utf8)
        }()

        return NoxMemoryRollupSnapshot(
            id: NoxMemoryRollupSnapshot.makeID(level: level, periodStart: periodStart),
            level: level,
            periodStart: periodStart,
            periodEnd: periodEnd,
            generatedAt: Date(),
            version: 2,
            facts: facts,
            summaryText: buildNarrative(facts: facts, level: level),
            sourceCountsJson: sourceJson
        )
    }

    // MARK: - Private

    private static func topApps(from spans: [NoxActivitySpan], limit: Int) -> [NoxRollupAppShare] {
        var totals: [String: (name: String, bundleId: String, ms: Int)] = [:]
        for span in spans {
            totals[span.bundleId] = (
                name: span.appName,
                bundleId: span.bundleId,
                ms: (totals[span.bundleId]?.ms ?? 0) + span.durationMs
            )
        }
        return totals.values.sorted { $0.ms > $1.ms }.prefix(limit)
            .map { NoxRollupAppShare(name: $0.name, bundleId: $0.bundleId, durationMs: $0.ms) }
    }

    private static func topCategories(from spans: [NoxActivitySpan], limit: Int) -> [NoxRollupCategoryShare] {
        var totals: [NoxActivityCategory: Int] = [:]
        for span in spans {
            totals[span.category, default: 0] += span.durationMs
        }
        return totals.sorted { $0.value > $1.value }.prefix(limit)
            .map { NoxRollupCategoryShare(category: $0.key.rawValue, durationMs: $0.value) }
    }

    private static func mergeAppShares(_ shares: [NoxRollupAppShare], limit: Int) -> [NoxRollupAppShare] {
        var totals: [String: NoxRollupAppShare] = [:]
        for share in shares {
            if let existing = totals[share.bundleId] {
                totals[share.bundleId] = NoxRollupAppShare(
                    name: existing.name,
                    bundleId: share.bundleId,
                    durationMs: existing.durationMs + share.durationMs
                )
            } else {
                totals[share.bundleId] = share
            }
        }
        return totals.values.sorted { $0.durationMs > $1.durationMs }.prefix(limit).map { $0 }
    }

    private static func mergeCategoryShares(
        _ shares: [NoxRollupCategoryShare],
        limit: Int
    ) -> [NoxRollupCategoryShare] {
        var totals: [String: Int] = [:]
        for share in shares {
            totals[share.category, default: 0] += share.durationMs
        }
        return totals.sorted { $0.value > $1.value }.prefix(limit)
            .map { NoxRollupCategoryShare(category: $0.key, durationMs: $0.value) }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
