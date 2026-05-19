import Foundation

/// Explicit retention for hot / warm / cold layers and each compression horizon.
nonisolated struct NoxMemoryRetentionPolicy: Equatable, Sendable {
    // MARK: Hot (in-memory)

    var hotInteractionWindowSeconds: TimeInterval = 60
    var hotLiveSignalCapacity: Int = 24
    var hotLiveSignalMaxSeconds: TimeInterval = 600
    /// Raw interaction signals — never long-term; hours max if ever persisted.
    var hotInteractionPersistHours: Int = 0

    // MARK: Warm (days → weeks)

    var warmTimelineDays: Int = 14
    var warmInterruptionDays: Int = 14

    // MARK: Cold detail (months, then compressed away)

    var detailSpanDays: Int = 90
    var detailFocusBlockDays: Int = 90

    // MARK: Cold semantic (indefinite)

    var semanticMemoryIndefinite: Bool = true
    var workSessionsIndefinite: Bool = true
    var typedMemoryIndefinite: Bool = true

    // MARK: Horizon rollups

    var hourlyRollupLookbackHours: Int = 48
    var dailyRollupLookbackDays: Int = 90
    var hourlyRollupRetentionDays: Int? = 7
    var dailyRollupRetentionDays: Int? = 180
    var weeklyRollupRetentionDays: Int? = 730
    var monthlyRollupRetentionDays: Int? = nil
    var quarterlyRollupRetentionDays: Int? = nil
    var yearlyRollupRetentionDays: Int? = nil
    var eraRollupRetentionDays: Int? = nil

    var maintenanceIntervalSeconds: TimeInterval = 6 * 3600

    static let `default` = NoxMemoryRetentionPolicy()

    func retentionDays(for level: NoxMemoryCompressionLevel) -> Int? {
        switch level {
        case .hourly: hourlyRollupRetentionDays
        case .daily: dailyRollupRetentionDays
        case .weekly: weeklyRollupRetentionDays
        case .monthly: monthlyRollupRetentionDays
        case .quarterly: quarterlyRollupRetentionDays
        case .yearly: yearlyRollupRetentionDays
        case .era: eraRollupRetentionDays
        }
    }

    func layer(for level: NoxMemoryCompressionLevel) -> NoxMemoryLayer {
        switch level {
        case .hourly: .warm
        case .daily, .weekly, .monthly, .quarterly, .yearly, .era: .cold
        }
    }
}
