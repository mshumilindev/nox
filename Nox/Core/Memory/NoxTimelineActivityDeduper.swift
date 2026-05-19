import Foundation

enum NoxTimelineActivityDeduper {

    /// Drops raw activity spans already represented by a semantic span on a overlapping interval.
    static func filter(
        activitySpans: [NoxActivitySpan],
        semanticSpans: [NoxSemanticMemorySpan],
        at date: Date = Date()
    ) -> [NoxActivitySpan] {
        guard !semanticSpans.isEmpty else { return activitySpans }
        return activitySpans.filter { activity in
            !semanticSpans.contains { semantic in
                isCovered(activity: activity, semantic: semantic, at: date)
            }
        }
    }

    private static func isCovered(
        activity: NoxActivitySpan,
        semantic: NoxSemanticMemorySpan,
        at date: Date
    ) -> Bool {
        let activityEnd = activity.endedAt ?? date
        let semanticEnd = semantic.endedAt ?? date
        let overlapStart = max(activity.startedAt, semantic.startedAt)
        let overlapEnd = min(activityEnd, semanticEnd)
        guard overlapEnd > overlapStart else { return false }

        let overlapSeconds = overlapEnd.timeIntervalSince(overlapStart)
        let activitySeconds = max(activityEnd.timeIntervalSince(activity.startedAt), 1)
        let overlapRatio = overlapSeconds / activitySeconds

        let contained = activity.startedAt >= semantic.startedAt
            && activityEnd <= semanticEnd.addingTimeInterval(30)

        return overlapRatio >= 0.5 || contained
    }
}
