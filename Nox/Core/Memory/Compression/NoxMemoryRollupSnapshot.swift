import Foundation

struct NoxMemoryRollupSnapshot: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let level: NoxMemoryCompressionLevel
    let periodStart: Date
    let periodEnd: Date
    let generatedAt: Date
    let version: Int
    let facts: NoxRollupFacts
    /// Template-based narrative — each horizon answers a different question.
    let summaryText: String
    let sourceCountsJson: String?

    static func makeID(level: NoxMemoryCompressionLevel, periodStart: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = level == .hourly
            ? [.withFullDate, .withTime]
            : [.withFullDate]
        return "\(level.rawValue)-\(formatter.string(from: periodStart))"
    }
}

struct NoxMaintenanceReport: Equatable, Sendable {
    let hourlyRollupsCreated: Int
    let dailyRollupsCreated: Int
    let weeklyRollupsCreated: Int
    let monthlyRollupsCreated: Int
    let quarterlyRollupsCreated: Int
    let yearlyRollupsCreated: Int
    let eraRollupsCreated: Int
    let typedMemoriesCreated: Int
    let timelineEventsPruned: Int
    let interruptionsPruned: Int
    let spansPruned: Int
    let focusBlocksPruned: Int
    let rollupsPruned: Int

    static let empty = NoxMaintenanceReport(
        hourlyRollupsCreated: 0,
        dailyRollupsCreated: 0,
        weeklyRollupsCreated: 0,
        monthlyRollupsCreated: 0,
        quarterlyRollupsCreated: 0,
        yearlyRollupsCreated: 0,
        eraRollupsCreated: 0,
        typedMemoriesCreated: 0,
        timelineEventsPruned: 0,
        interruptionsPruned: 0,
        spansPruned: 0,
        focusBlocksPruned: 0,
        rollupsPruned: 0
    )
}
