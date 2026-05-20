import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

public enum NoxMemoryPeriod: String, CaseIterable, Identifiable, Sendable {
    case today
    case yesterday
    case lastSevenDays

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .today: "Today"
        case .yesterday: "Yesterday"
        case .lastSevenDays: "Last 7 days"
        }
    }

    public var symbolName: String {
        switch self {
        case .today: "sun.max"
        case .yesterday: "moon"
        case .lastSevenDays: "calendar"
        }
    }

    public func dateRange(calendar: Calendar = .current) -> (start: Date, end: Date) {
        let end = Date()
        switch self {
        case .today:
            let start = calendar.startOfDay(for: end)
            return (start, end)
        case .yesterday:
            let todayStart = calendar.startOfDay(for: end)
            let start = calendar.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart
            return (start, todayStart)
        case .lastSevenDays:
            let start = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: end)) ?? end
            return (start, end)
        }
    }
}
