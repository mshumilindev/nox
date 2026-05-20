import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

/// Structured facts for a compression horizon. Layer-specific fields carry different semantics.
public nonisolated struct NoxRollupFacts: Codable, Equatable, Sendable {
    public init(
        totalActiveMs: Int = 0,
        sessionCount: Int = 0,
        dominantApps: [NoxRollupAppShare] = []
    ) {
        self.totalActiveMs = totalActiveMs
        self.sessionCount = sessionCount
        self.dominantApps = dominantApps
    }

    public var totalActiveMs: Int = 0
    public var focusedMs: Int = 0
    public var fragmentedMs: Int = 0
    public var sessionCount: Int = 0
    public var semanticSpanCount: Int = 0
    public var interruptionCount: Int = 0
    public var appSwitchCount: Int = 0
    public var longestFocusBlockMs: Int = 0
    public var longestFocusApp: String?
    public var dominantApps: [NoxRollupAppShare] = []
    public var dominantCategories: [NoxRollupCategoryShare] = []
    public var topSemanticTitles: [String] = []
    public var recurringContexts: [String] = []
    public var childRollupCount: Int = 0

    // Hourly — short continuity
    public var hourlyContinuityWindows: [NoxContinuityWindow] = []

    // Weekly — what repeated
    public var repeatedWorkflows: [NoxRepeatedPattern] = []

    // Monthly — stable patterns
    public var stablePatterns: [String] = []

    // Quarterly — direction
    public var directionalThemes: [String] = []

    // Yearly — change
    public var majorShifts: [String] = []

    // Era — adaptive life/work phase (not fixed calendar decade)
    public var eraLabel: String?
    public var eraThemes: [String] = []

    public var typedMemoryIds: [String] = []
}

public nonisolated struct NoxRollupAppShare: Codable, Equatable, Sendable {
    public let name: String
    public let bundleId: String
    public let durationMs: Int

    public init(name: String, bundleId: String, durationMs: Int) {
        self.name = name
        self.bundleId = bundleId
        self.durationMs = durationMs
    }
}

nonisolated public struct NoxRollupCategoryShare: Codable, Equatable, Sendable {
    public let category: String
    public let durationMs: Int
}

nonisolated public struct NoxContinuityWindow: Codable, Equatable, Sendable {
    public let appName: String
    public let bundleId: String
    public let durationMs: Int
    public let contextLabel: String?
}

public nonisolated struct NoxRepeatedPattern: Codable, Equatable, Sendable {
    public let label: String
    public let occurrenceCount: Int
    public let totalDurationMs: Int

    public init(label: String, occurrenceCount: Int, totalDurationMs: Int) {
        self.label = label
        self.occurrenceCount = occurrenceCount
        self.totalDurationMs = totalDurationMs
    }
}
