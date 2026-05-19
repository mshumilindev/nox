import Foundation

/// Copy for historical memory periods — never uses live open-span state.
enum NoxMemoryPeriodEmptyCopy {

    static func title(period: NoxMemoryPeriod, stats: NoxMemoryDayStats) -> String {
        switch period {
        case .today:
            return NoxHumanContextCopy.recentContextSettling
        case .yesterday:
            if stats.totalActiveMs >= 60_000 {
                return "Yesterday was light in stored memory"
            }
            return "Little was recorded for yesterday"
        case .lastSevenDays:
            if stats.totalActiveMs >= 120_000 {
                return "This week is still sparse in memory"
            }
            return "Few durable spans across the last seven days"
        }
    }

    static func detail(period: NoxMemoryPeriod) -> String {
        switch period {
        case .today:
            return NoxHumanContextCopy.contextsGathering
        case .yesterday, .lastSevenDays:
            return "Historical view only — live context is not shown here."
        }
    }
}
