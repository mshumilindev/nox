import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

public struct NoxMemoryRollupSnapshot: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let level: NoxMemoryCompressionLevel
    public let periodStart: Date
    public let periodEnd: Date
    public let generatedAt: Date
    public let version: Int
    public let facts: NoxRollupFacts
    /// Template-based narrative — each horizon answers a different question.
    public let summaryText: String
    public let sourceCountsJson: String?

    public init(
        id: String,
        level: NoxMemoryCompressionLevel,
        periodStart: Date,
        periodEnd: Date,
        generatedAt: Date,
        version: Int,
        facts: NoxRollupFacts,
        summaryText: String,
        sourceCountsJson: String?
    ) {
        self.id = id
        self.level = level
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.generatedAt = generatedAt
        self.version = version
        self.facts = facts
        self.summaryText = summaryText
        self.sourceCountsJson = sourceCountsJson
    }

    public static func makeID(level: NoxMemoryCompressionLevel, periodStart: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = level == .hourly
            ? [.withFullDate, .withTime]
            : [.withFullDate]
        return "\(level.rawValue)-\(formatter.string(from: periodStart))"
    }
}

public struct NoxMaintenanceReport: Equatable, Sendable {
    public let hourlyRollupsCreated: Int
    public let dailyRollupsCreated: Int
    public let weeklyRollupsCreated: Int
    public let monthlyRollupsCreated: Int
    public let quarterlyRollupsCreated: Int
    public let yearlyRollupsCreated: Int
    public let eraRollupsCreated: Int
    public let typedMemoriesCreated: Int
    public let timelineEventsPruned: Int
    public let interruptionsPruned: Int
    public let spansPruned: Int
    public let focusBlocksPruned: Int
    public let rollupsPruned: Int

    public init(
        hourlyRollupsCreated: Int,
        dailyRollupsCreated: Int,
        weeklyRollupsCreated: Int,
        monthlyRollupsCreated: Int,
        quarterlyRollupsCreated: Int,
        yearlyRollupsCreated: Int,
        eraRollupsCreated: Int,
        typedMemoriesCreated: Int,
        timelineEventsPruned: Int,
        interruptionsPruned: Int,
        spansPruned: Int,
        focusBlocksPruned: Int,
        rollupsPruned: Int
    ) {
        self.hourlyRollupsCreated = hourlyRollupsCreated
        self.dailyRollupsCreated = dailyRollupsCreated
        self.weeklyRollupsCreated = weeklyRollupsCreated
        self.monthlyRollupsCreated = monthlyRollupsCreated
        self.quarterlyRollupsCreated = quarterlyRollupsCreated
        self.yearlyRollupsCreated = yearlyRollupsCreated
        self.eraRollupsCreated = eraRollupsCreated
        self.typedMemoriesCreated = typedMemoriesCreated
        self.timelineEventsPruned = timelineEventsPruned
        self.interruptionsPruned = interruptionsPruned
        self.spansPruned = spansPruned
        self.focusBlocksPruned = focusBlocksPruned
        self.rollupsPruned = rollupsPruned
    }

    public static let empty = NoxMaintenanceReport(
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
