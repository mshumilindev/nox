import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

public enum NoxRollupPeriodCalendar {

    public static func hourRange(containing date: Date, calendar: Calendar = .current) -> (start: Date, end: Date) {
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        let start = calendar.date(from: components) ?? date
        let end = calendar.date(byAdding: .hour, value: 1, to: start) ?? start.addingTimeInterval(3600)
        return (start, end)
    }

    public static func dayRange(for date: Date, calendar: Calendar = .current) -> (start: Date, end: Date) {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return (start, end)
    }

    public static func weekRange(containing date: Date, calendar: Calendar = .current) -> (start: Date, end: Date) {
        var cal = calendar
        cal.firstWeekday = 2
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let start = cal.date(from: components) ?? calendar.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 7, to: start) ?? start.addingTimeInterval(7 * 86_400)
        return (start, end)
    }

    public static func monthRange(containing date: Date, calendar: Calendar = .current) -> (start: Date, end: Date) {
        let components = calendar.dateComponents([.year, .month], from: date)
        let start = calendar.date(from: components) ?? calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start.addingTimeInterval(30 * 86_400)
        return (start, end)
    }

    public static func quarterRange(containing date: Date, calendar: Calendar = .current) -> (start: Date, end: Date) {
        let month = calendar.component(.month, from: date)
        let quarterStartMonth = ((month - 1) / 3) * 3 + 1
        var components = calendar.dateComponents([.year], from: date)
        components.month = quarterStartMonth
        components.day = 1
        let start = calendar.date(from: components) ?? calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .month, value: 3, to: start) ?? start.addingTimeInterval(90 * 86_400)
        return (start, end)
    }

    public static func yearRange(containing date: Date, calendar: Calendar = .current) -> (start: Date, end: Date) {
        let components = calendar.dateComponents([.year], from: date)
        let start = calendar.date(from: components) ?? calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .year, value: 1, to: start) ?? start.addingTimeInterval(365 * 86_400)
        return (start, end)
    }

    /// Adaptive era window — caller supplies detected boundaries.
    public static func eraRange(start: Date, end: Date) -> (start: Date, end: Date) {
        (start, end)
    }

    public static func periodRange(
        for level: NoxMemoryCompressionLevel,
        containing date: Date,
        calendar: Calendar = .current
    ) -> (start: Date, end: Date) {
        switch level {
        case .hourly: hourRange(containing: date, calendar: calendar)
        case .daily: dayRange(for: date, calendar: calendar)
        case .weekly: weekRange(containing: date, calendar: calendar)
        case .monthly: monthRange(containing: date, calendar: calendar)
        case .quarterly: quarterRange(containing: date, calendar: calendar)
        case .yearly: yearRange(containing: date, calendar: calendar)
        case .era: (calendar.startOfDay(for: date), date)
        }
    }

    public static func completedDays(
        lookbackDays: Int,
        before date: Date = Date(),
        calendar: Calendar = .current
    ) -> [Date] {
        let todayStart = calendar.startOfDay(for: date)
        return (1...lookbackDays).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: todayStart)
        }
    }

    public static func completedHours(
        lookbackHours: Int,
        before date: Date = Date(),
        calendar: Calendar = .current
    ) -> [Date] {
        let currentHour = hourRange(containing: date, calendar: calendar).start
        return (1...lookbackHours).compactMap { offset in
            calendar.date(byAdding: .hour, value: -offset, to: currentHour)
        }
    }
}
