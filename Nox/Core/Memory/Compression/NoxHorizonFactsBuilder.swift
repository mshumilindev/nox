import Foundation

/// Enriches rollup facts with horizon-specific semantic extractions.
enum NoxHorizonFactsBuilder {

    static func buildHourly(
        spans: [NoxActivitySpan],
        at range: (start: Date, end: Date)
    ) -> NoxRollupFacts {
        let filtered = spans.filter { !$0.category.excludedFromAnalysis }
        var facts = NoxRollupFacts()
        facts.totalActiveMs = filtered.reduce(0) { $0 + $1.durationMs }
        facts.appSwitchCount = max(0, filtered.count - 1)
        facts.dominantApps = topApps(from: filtered, limit: 3)
        facts.hourlyContinuityWindows = filtered
            .sorted { $0.durationMs > $1.durationMs }
            .prefix(3)
            .map {
                NoxContinuityWindow(
                    appName: $0.appName,
                    bundleId: $0.bundleId,
                    durationMs: $0.durationMs,
                    contextLabel: $0.contextLabel
                )
            }
        _ = range
        return facts
    }

    static func enrich(_ facts: NoxRollupFacts, level: NoxMemoryCompressionLevel, children: [NoxRollupFacts]) -> NoxRollupFacts {
        var enriched = facts
        switch level {
        case .weekly:
            enriched.repeatedWorkflows = detectRepeatedWorkflows(from: children)
            enriched.recurringContexts = mergeRecurringContexts(children)
        case .monthly:
            enriched.stablePatterns = detectStablePatterns(from: children, facts: facts)
        case .quarterly:
            enriched.directionalThemes = detectDirectionalThemes(from: children)
        case .yearly:
            enriched.majorShifts = detectMajorShifts(from: children)
        case .era:
            let era = NoxEraDetector.deriveEraFacts(from: children)
            enriched.eraLabel = era.eraLabel
            enriched.eraThemes = era.eraThemes
        default:
            break
        }
        return enriched
    }

    // MARK: - Private

    private static func detectRepeatedWorkflows(from dailies: [NoxRollupFacts]) -> [NoxRepeatedPattern] {
        var titleCounts: [String: (count: Int, ms: Int)] = [:]
        for day in dailies {
            for title in day.topSemanticTitles {
                let key = title.lowercased()
                let existing = titleCounts[key]
                titleCounts[key] = (count: (existing?.count ?? 0) + 1, ms: (existing?.ms ?? 0) + day.totalActiveMs)
            }
            for app in day.dominantApps.prefix(2) {
                let key = "\(app.name) workflow"
                let existing = titleCounts[key]
                titleCounts[key] = (count: (existing?.count ?? 0) + 1, ms: (existing?.ms ?? 0) + app.durationMs)
            }
        }
        return titleCounts
            .filter { $0.value.count >= 2 }
            .sorted { $0.value.count > $1.value.count }
            .prefix(4)
            .map { NoxRepeatedPattern(label: $0.key, occurrenceCount: $0.value.count, totalDurationMs: $0.value.ms) }
    }

    private static func mergeRecurringContexts(_ children: [NoxRollupFacts]) -> [String] {
        var counts: [String: Int] = [:]
        for child in children {
            for ctx in child.recurringContexts {
                counts[ctx, default: 0] += 1
            }
        }
        return counts.filter { $0.value >= 2 }.sorted { $0.value > $1.value }.map(\.key).prefix(6).map { $0 }
    }

    private static func detectStablePatterns(from weeks: [NoxRollupFacts], facts: NoxRollupFacts) -> [String] {
        var patterns: [String] = []
        if let category = facts.dominantCategories.first {
            let hours = category.durationMs / 3_600_000
            if hours >= 10 {
                patterns.append("Stable \(category.category.lowercased()) focus (~\(hours)h)")
            }
        }
        let workflows = weeks.flatMap(\.repeatedWorkflows)
        if let top = workflows.max(by: { $0.occurrenceCount < $1.occurrenceCount }) {
            patterns.append("Recurring \(top.label)")
        }
        if let app = facts.dominantApps.first, app.durationMs > facts.totalActiveMs / 2 {
            patterns.append("Ongoing focus on \(app.name)")
        }
        return patterns
    }

    private static func detectDirectionalThemes(from monthlies: [NoxRollupFacts]) -> [String] {
        guard monthlies.count >= 2 else {
            return monthlies.flatMap(\.stablePatterns).prefix(2).map { $0 }
        }
        let first = monthlies.first?.dominantCategories.first?.category
        let last = monthlies.last?.dominantCategories.first?.category
        if let first, let last, first != last {
            return ["Shift from \(first.lowercased()) toward \(last.lowercased())"]
        }
        return monthlies.flatMap(\.stablePatterns).uniqued().prefix(3).map { $0 }
    }

    private static func detectMajorShifts(from quarterlies: [NoxRollupFacts]) -> [String] {
        guard let latest = quarterlies.last else { return [] }
        var shifts: [String] = []
        if let app = latest.dominantApps.first {
            shifts.append("Growing investment in \(app.name)")
        }
        for theme in latest.directionalThemes.prefix(2) {
            shifts.append(theme)
        }
        if latest.semanticSpanCount > 0 {
            shifts.append("Increased semantic depth in tracked activity")
        }
        return shifts
    }

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
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
