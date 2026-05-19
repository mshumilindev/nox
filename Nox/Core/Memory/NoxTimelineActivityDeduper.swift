import Foundation

nonisolated enum NoxTimelineActivityDeduper {

    /// Drops raw activity spans already represented by a semantic span on the same time window.
    static func filter(
        activitySpans: [NoxActivitySpan],
        semanticSpans: [NoxSemanticMemorySpan],
        at date: Date = Date()
    ) -> [NoxActivitySpan] {
        guard !semanticSpans.isEmpty else { return activitySpans }
        let semanticIntervals = semanticSpans.map {
            NoxTimeInterval(start: $0.startedAt, end: $0.endedAt ?? date)
        }
        return activitySpans.filter { activity in
            let activityInterval = NoxTimeInterval(start: activity.startedAt, end: activity.endedAt ?? date)
            return !semanticIntervals.contains { activityInterval.overlaps($0) }
        }
    }

    static func unionTimeWindows(
        activitySpans: [NoxActivitySpan],
        semanticSpans: [NoxSemanticMemorySpan],
        at date: Date = Date()
    ) -> [NoxTimeInterval] {
        NoxTimeIntervalMerge.union(activitySpans: activitySpans, semanticSpans: semanticSpans, at: date)
    }
}
