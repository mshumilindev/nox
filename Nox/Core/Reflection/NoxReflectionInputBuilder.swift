import Foundation

enum NoxReflectionInputBuilder {

    static func build(
        period: NoxMemoryPeriod,
        spans: [NoxSemanticMemorySpan],
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        stats: NoxMemoryDayStats,
        at date: Date = Date()
    ) -> NoxReflectionInput {
        let themes = themeLabels(from: spans, arcs: arcs)
        let resumptions = threads.reduce(0) { $0 + $1.totalResumptions }
        let fragmented = spans.filter {
            $0.semanticState == .fragmentedInteraction ||
            $0.title.lowercased().contains("fragmented")
        }.count

        let lookbackStart = date.addingTimeInterval(-48 * 3600)
        let priorActivity = spans.contains { $0.startedAt < lookbackStart }

        return NoxReflectionInput(
            periodLabel: period.title,
            semanticThemes: themes,
            continuityResumptions: resumptions,
            fragmentedSessions: fragmented,
            dominantArcLabels: arcs.prefix(3).map(\.label),
            recurringThreadTitles: threads
                .filter { $0.recurrenceStrength >= 0.4 }
                .prefix(3)
                .map(\.title),
            observationHours: max(1, Int(stats.totalActiveMs / 3_600_000)),
            hasPriorDayActivity: priorActivity
        )
    }

    private static func themeLabels(
        from spans: [NoxSemanticMemorySpan],
        arcs: [NoxSemanticArc]
    ) -> [String] {
        if !arcs.isEmpty {
            return arcs.prefix(4).map(\.label)
        }
        return Array(Set(spans.map(\.title))).prefix(4).map { $0 }
    }
}
