import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

/// Explicit retention for hot / warm / cold layers and each compression horizon.
nonisolated public struct NoxMemoryRetentionPolicy: Equatable, Sendable {
    // MARK: Hot (in-memory)

    public var hotInteractionWindowSeconds: TimeInterval = 60
    public var hotLiveSignalCapacity: Int = 24
    public var hotLiveSignalMaxSeconds: TimeInterval = 600
    /// Raw interaction signals — never long-term; hours max if ever persisted.
    public var hotInteractionPersistHours: Int = 0

    // MARK: Warm (days → weeks)

    public var warmTimelineDays: Int = 14
    public var warmInterruptionDays: Int = 14

    // MARK: Cold detail (months, then compressed away)

    public var detailSpanDays: Int = 90
    public var detailFocusBlockDays: Int = 90

    // MARK: Cold semantic (indefinite)

    public var semanticMemoryIndefinite: Bool = true
    public var workSessionsIndefinite: Bool = true
    public var typedMemoryIndefinite: Bool = true

    // MARK: Horizon rollups

    public var hourlyRollupLookbackHours: Int = 48
    public var dailyRollupLookbackDays: Int = 90
    public var hourlyRollupRetentionDays: Int? = 7
    public var dailyRollupRetentionDays: Int? = 180
    public var weeklyRollupRetentionDays: Int? = 730
    public var monthlyRollupRetentionDays: Int? = nil
    public var quarterlyRollupRetentionDays: Int? = nil
    public var yearlyRollupRetentionDays: Int? = nil
    public var eraRollupRetentionDays: Int? = nil

    public var maintenanceIntervalSeconds: TimeInterval = 6 * 3600

    public static let `default` = NoxMemoryRetentionPolicy()

    public func retentionDays(for level: NoxMemoryCompressionLevel) -> Int? {
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

    public func layer(for level: NoxMemoryCompressionLevel) -> NoxMemoryLayer {
        switch level {
        case .hourly: .warm
        case .daily, .weekly, .monthly, .quarterly, .yearly, .era: .cold
        }
    }
}
