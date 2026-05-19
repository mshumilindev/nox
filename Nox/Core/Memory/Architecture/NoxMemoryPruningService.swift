import Foundation

/// Applies retention policies: prune warm noise after meaning is compressed.
struct NoxMemoryPruningService {
    let policy: NoxMemoryRetentionPolicy

    func pruneWarmTimeline(using timelineStore: NoxTimelineStore, at date: Date = Date()) async throws -> Int {
        _ = date
        return try await timelineStore.pruneOldEvents(olderThan: policy.warmTimelineDays)
    }

    func pruneWarmInterruptions(using memoryStore: NoxMemoryStore, at date: Date = Date()) async throws -> Int {
        let cutoff = date.addingTimeInterval(-Double(policy.warmInterruptionDays) * 86_400)
        return try await memoryStore.deleteInterruptions(before: cutoff)
    }

    func pruneDetailFocusBlocks(using memoryStore: NoxMemoryStore, at date: Date = Date()) async throws -> Int {
        let cutoff = date.addingTimeInterval(-Double(policy.detailFocusBlockDays) * 86_400)
        return try await memoryStore.deleteFocusBlocks(before: cutoff)
    }

    /// Removes activity spans for days older than `detailSpanDays` only when a daily rollup exists.
    func pruneCompressedSpans(
        using memoryStore: NoxMemoryStore,
        rollupStore: NoxMemoryRollupStore,
        at date: Date = Date(),
        calendar: Calendar = .current
    ) async throws -> Int {
        let todayStart = calendar.startOfDay(for: date)
        var pruned = 0

        for offset in policy.detailSpanDays...(policy.detailSpanDays + 30) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: todayStart) else { continue }
            let range = NoxRollupPeriodCalendar.dayRange(for: day, calendar: calendar)
            let hasRollup = try await rollupStore.exists(level: .daily, periodStart: range.start)
            guard hasRollup else { continue }
            pruned += try await memoryStore.deleteSpans(inRange: range.start, to: range.end)
        }

        return pruned
    }

    func pruneExpiredRollups(using rollupStore: NoxMemoryRollupStore, at date: Date = Date()) async throws -> Int {
        var total = 0
        for level in NoxMemoryCompressionLevel.allCases {
            guard let retentionDays = policy.retentionDays(for: level) else { continue }
            let cutoff = date.addingTimeInterval(-Double(retentionDays) * 86_400)
            total += try await rollupStore.deleteRollups(level: level, before: cutoff)
        }
        return total
    }
}
