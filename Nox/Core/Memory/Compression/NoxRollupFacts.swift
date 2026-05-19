import Foundation

/// Structured facts for a compression horizon. Layer-specific fields carry different semantics.
struct NoxRollupFacts: Codable, Equatable, Sendable {
    var totalActiveMs: Int = 0
    var focusedMs: Int = 0
    var fragmentedMs: Int = 0
    var sessionCount: Int = 0
    var semanticSpanCount: Int = 0
    var interruptionCount: Int = 0
    var appSwitchCount: Int = 0
    var longestFocusBlockMs: Int = 0
    var longestFocusApp: String?
    var dominantApps: [NoxRollupAppShare] = []
    var dominantCategories: [NoxRollupCategoryShare] = []
    var topSemanticTitles: [String] = []
    var recurringContexts: [String] = []
    var childRollupCount: Int = 0

    // Hourly — short continuity
    var hourlyContinuityWindows: [NoxContinuityWindow] = []

    // Weekly — what repeated
    var repeatedWorkflows: [NoxRepeatedPattern] = []

    // Monthly — stable patterns
    var stablePatterns: [String] = []

    // Quarterly — direction
    var directionalThemes: [String] = []

    // Yearly — change
    var majorShifts: [String] = []

    // Era — adaptive life/work phase (not fixed calendar decade)
    var eraLabel: String?
    var eraThemes: [String] = []

    var typedMemoryIds: [String] = []
}

struct NoxRollupAppShare: Codable, Equatable, Sendable {
    let name: String
    let bundleId: String
    let durationMs: Int
}

struct NoxRollupCategoryShare: Codable, Equatable, Sendable {
    let category: String
    let durationMs: Int
}

struct NoxContinuityWindow: Codable, Equatable, Sendable {
    let appName: String
    let bundleId: String
    let durationMs: Int
    let contextLabel: String?
}

struct NoxRepeatedPattern: Codable, Equatable, Sendable {
    let label: String
    let occurrenceCount: Int
    let totalDurationMs: Int
}
