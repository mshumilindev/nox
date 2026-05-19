import Foundation

/// Adaptive era detection — emerges from continuity, not fixed calendar decades.
enum NoxEraDetector {

    struct EraCandidate: Equatable, Sendable {
        let label: String
        let themes: [String]
        let periodStart: Date
        let periodEnd: Date
    }

    static func deriveEraFacts(from yearlyOrMonthly: [NoxRollupFacts]) -> (eraLabel: String?, eraThemes: [String]) {
        guard !yearlyOrMonthly.isEmpty else { return (nil, []) }

        let dominantCategory = mergeCategories(yearlyOrMonthly).first?.category
        let dominantApp = mergeApps(yearlyOrMonthly).first?.name
        let semanticThemes = yearlyOrMonthly.flatMap(\.topSemanticTitles).uniqued().prefix(4).map { $0 }

        var themes: [String] = []
        if let dominantCategory {
            themes.append("\(dominantCategory.lowercased())-oriented period")
        }
        themes.append(contentsOf: semanticThemes)

        let label: String
        if let app = dominantApp, app.lowercased().contains("cursor") || app.lowercased().contains("xcode") {
            label = "Development-focused era"
        } else if semanticThemes.contains(where: { $0.lowercased().contains("ai") }) {
            label = "AI-orchestrated work era"
        } else if let first = semanticThemes.first {
            label = "\(first) era"
        } else if let app = dominantApp {
            label = "\(app)-centered era"
        } else {
            label = "Sustained activity era"
        }

        return (label, Array(themes.prefix(5)))
    }

    static func detectEraCandidates(
        from rollups: [NoxMemoryRollupSnapshot],
        minimumMonths: Int = 2
    ) -> [EraCandidate] {
        let monthly = rollups.filter { $0.level == .monthly }.sorted { $0.periodStart < $1.periodStart }
        guard monthly.count >= minimumMonths else { return [] }

        var candidates: [EraCandidate] = []
        var cluster: [NoxMemoryRollupSnapshot] = []

        for rollup in monthly {
            let category = rollup.facts.dominantCategories.first?.category
            if let last = cluster.last,
               last.facts.dominantCategories.first?.category == category {
                cluster.append(rollup)
            } else {
                if cluster.count >= minimumMonths {
                    candidates.append(makeCandidate(from: cluster))
                }
                cluster = [rollup]
            }
        }
        if cluster.count >= minimumMonths {
            candidates.append(makeCandidate(from: cluster))
        }
        return candidates
    }

    private static func makeCandidate(from cluster: [NoxMemoryRollupSnapshot]) -> EraCandidate {
        let facts = cluster.map(\.facts)
        let derived = deriveEraFacts(from: facts)
        return EraCandidate(
            label: derived.eraLabel ?? "Sustained chapter",
            themes: derived.eraThemes,
            periodStart: cluster.first?.periodStart ?? Date(),
            periodEnd: cluster.last?.periodEnd ?? Date()
        )
    }

    private static func mergeCategories(_ facts: [NoxRollupFacts]) -> [NoxRollupCategoryShare] {
        var totals: [String: Int] = [:]
        for f in facts {
            for c in f.dominantCategories {
                totals[c.category, default: 0] += c.durationMs
            }
        }
        return totals.sorted { $0.value > $1.value }
            .map { NoxRollupCategoryShare(category: $0.key, durationMs: $0.value) }
    }

    private static func mergeApps(_ facts: [NoxRollupFacts]) -> [NoxRollupAppShare] {
        var totals: [String: (name: String, ms: Int)] = [:]
        for f in facts {
            for a in f.dominantApps {
                totals[a.bundleId] = (name: a.name, ms: (totals[a.bundleId]?.ms ?? 0) + a.durationMs)
            }
        }
        return totals.sorted { $0.value.ms > $1.value.ms }
            .map { NoxRollupAppShare(name: $0.value.name, bundleId: $0.key, durationMs: $0.value.ms) }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
