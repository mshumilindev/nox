import Foundation

struct NoxBehavioralStatistics {
    func compute(
        period: NoxMemoryPeriod,
        spans: [NoxActivitySpan],
        focusBlocks: [NoxFocusBlock],
        interruptions: [NoxInterruption]
    ) -> NoxMemoryDayStats {
        let totalActiveMs = spans.reduce(0) { $0 + $1.durationMs }
        let focusedMs = focusBlocks
            .filter { $0.kind == .focused || $0.kind == .deepWork }
            .reduce(0) { $0 + $1.durationMs }
        let fragmentedMs = focusBlocks
            .filter { $0.kind == .fragmented }
            .reduce(0) { $0 + $1.durationMs }
        let longestFocus = focusBlocks.map(\.durationMs).max() ?? 0
        let dominantApp = spans
            .reduce(into: [String: Int]()) { counts, span in
                counts[span.appName, default: 0] += span.durationMs
            }
            .max(by: { $0.value < $1.value })?
            .key
        let dominantCategory = spans
            .reduce(into: [NoxActivityCategory: Int]()) { counts, span in
                counts[span.category, default: 0] += span.durationMs
            }
            .max(by: { $0.value < $1.value })?
            .key

        return NoxMemoryDayStats(
            periodLabel: period.title,
            totalActiveMs: totalActiveMs,
            focusedMs: focusedMs,
            fragmentedMs: fragmentedMs,
            appSwitchCount: max(0, spans.count - 1),
            longestFocusBlockMs: longestFocus,
            dominantApp: dominantApp,
            dominantCategory: dominantCategory
        )
    }
}
