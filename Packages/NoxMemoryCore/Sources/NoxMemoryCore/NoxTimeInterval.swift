import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

nonisolated public struct NoxTimeInterval: Equatable, Sendable {
    public let start: Date
    public let end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = max(end, start)
    }

    var duration: TimeInterval {
        max(0, end.timeIntervalSince(start))
    }

    /// True when intervals share meaningful time — used for activity vs semantic dedup.
    public func overlaps(
        _ other: NoxTimeInterval,
        minimumOverlapSeconds: TimeInterval = 30,
        minimumOverlapRatio: Double = 0.5
    ) -> Bool {
        let overlapStart = max(start, other.start)
        let overlapEnd = min(end, other.end)
        guard overlapEnd > overlapStart else { return false }

        let overlap = overlapEnd.timeIntervalSince(overlapStart)
        if overlap >= minimumOverlapSeconds { return true }

        let shorter = min(duration, other.duration)
        guard shorter > 0 else { return false }
        if overlap / shorter >= minimumOverlapRatio { return true }

        return start >= other.start && end <= other.end.addingTimeInterval(30)
    }
}

nonisolated public enum NoxTimeIntervalMerge {
    public static func union(
        activitySpans: [NoxActivitySpan],
        semanticSpans: [NoxSemanticMemorySpan],
        at date: Date = Date()
    ) -> [NoxTimeInterval] {
        var intervals: [NoxTimeInterval] = []
        for span in activitySpans {
            intervals.append(NoxTimeInterval(start: span.startedAt, end: span.endedAt ?? date))
        }
        for span in semanticSpans {
            intervals.append(NoxTimeInterval(start: span.startedAt, end: span.endedAt ?? date))
        }
        return merge(intervals)
    }

    public static func merge(_ intervals: [NoxTimeInterval]) -> [NoxTimeInterval] {
        guard !intervals.isEmpty else { return [] }
        let sorted = intervals.sorted { $0.start < $1.start }
        var merged: [NoxTimeInterval] = [sorted[0]]
        for interval in sorted.dropFirst() {
            var last = merged[merged.count - 1]
            if interval.start <= last.end.addingTimeInterval(60) {
                last = NoxTimeInterval(start: last.start, end: max(last.end, interval.end))
                merged[merged.count - 1] = last
            } else {
                merged.append(interval)
            }
        }
        return merged
    }

    public static func intersectsAny(_ interval: NoxTimeInterval, windows: [NoxTimeInterval]) -> Bool {
        windows.contains { interval.overlaps($0, minimumOverlapSeconds: 1, minimumOverlapRatio: 0.01) }
    }
}
