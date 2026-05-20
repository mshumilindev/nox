import Foundation

nonisolated enum NoxSystemContradictionType: String, Codable, Sendable, CaseIterable {
    case sleepFocusDuringActiveWork
    case longSessionWithoutDisplayProtection
    case highInterruptionCostWithoutQuietState
    case recoveryWindowAfterLongFocus
    case batterySensitiveLongSession
    case contextMismatchAfterReturn
}

nonisolated enum NoxFocusSystemReading: String, Sendable {
    case unknown
    case available
    case focused
    case doNotDisturb
}

nonisolated struct NoxSystemStateSnapshot: Equatable, Sendable {
    let focusReading: NoxFocusSystemReading
    let focusAuthorized: Bool
    let displaySleepPrevented: Bool
    let noxCaffeinateActive: Bool
    let batteryLevel: Double?
    let isCharging: Bool
    let onExternalPower: Bool
    let lowPowerModeEnabled: Bool
    let externalDisplayConnected: Bool
    let appearanceIsDark: Bool
    let hourOfDay: Int
    let signalsReliable: Bool

    static let unknown = NoxSystemStateSnapshot(
        focusReading: .unknown,
        focusAuthorized: false,
        displaySleepPrevented: false,
        noxCaffeinateActive: false,
        batteryLevel: nil,
        isCharging: false,
        onExternalPower: false,
        lowPowerModeEnabled: false,
        externalDisplayConnected: false,
        appearanceIsDark: true,
        hourOfDay: 12,
        signalsReliable: false
    )
}

nonisolated struct NoxSystemActionCandidate: Identifiable, Equatable, Sendable {
    let id: String
    let kind: NoxSystemActionKind
    let title: String
    let detail: String
    let safetyLevel: NoxSystemActionSafetyLevel
    let requiresConfirmation: Bool
    let explainabilityReason: String
    let fallbackWhenUnavailable: String?
}

nonisolated enum NoxSystemActionKind: String, Codable, Sendable {
    case openFocusSettings
    case openBatterySettings
    case startCaffeinate30
    case startCaffeinate60
    case startCaffeinateUntilSessionEnd
    case stopCaffeinate
    case reduceResurfacingQuiet
    case dismiss
}

nonisolated enum NoxSystemActionSafetyLevel: String, Sendable {
    case informational
    case userConfirmed
    case settingsOnly
}

nonisolated struct NoxSystemContradiction: Identifiable, Equatable, Sendable {
    let id: String
    let type: NoxSystemContradictionType
    let label: String
    let detail: String
    let confidence: Double
    let explainabilityDetail: String
    let actions: [NoxSystemActionCandidate]
}

nonisolated struct NoxCaffeinateSession: Codable, Equatable, Sendable {
    var startedAt: Date
    var durationSeconds: TimeInterval?
    var reason: String
    var stoppedAt: Date?

    var isActive: Bool { stoppedAt == nil }

    var expiresAt: Date? {
        guard let durationSeconds else { return nil }
        return startedAt.addingTimeInterval(durationSeconds)
    }
}

nonisolated struct NoxSystemActionRecord: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let actionKind: NoxSystemActionKind
    let contradictionType: NoxSystemContradictionType?
    let performedAt: Date
    let outcome: String
}

nonisolated struct NoxSystemStatePersistence: Codable, Equatable, Sendable {
    var lastSystemInterventionAt: Date?
    var dismissedContradictions: [String: Date]
    var caffeinateSession: NoxCaffeinateSession?
    var resurfacingQuietUntil: Date?
    var actionHistory: [NoxSystemActionRecord]

    static let initial = NoxSystemStatePersistence(
        lastSystemInterventionAt: nil,
        dismissedContradictions: [:],
        caffeinateSession: nil,
        resurfacingQuietUntil: nil,
        actionHistory: []
    )
}

nonisolated struct NoxSystemStatePreferences: Codable, Equatable, Sendable {
    var contradictionSuggestionsEnabled: Bool
    var caffeinateSuggestionsEnabled: Bool

    static let `default` = NoxSystemStatePreferences(
        contradictionSuggestionsEnabled: true,
        caffeinateSuggestionsEnabled: true
    )
}

nonisolated struct NoxSystemContradictionContext: Sendable {
    let stats: NoxMemoryDayStats
    let focus: NoxFocusAnalysis?
    let threads: [NoxContinuityThread]
    let receptiveness: NoxInterventionReceptiveness
    let decompression: NoxDecompressionState
    let recoveryWindow: NoxRecoveryWindowModel
    let preferSilence: Bool
    let interruptionCost: Double
    let observationContinuitySeconds: TimeInterval
    let isUserIdle: Bool
    let dominantCategory: NoxActivityCategory?
    let returningAfterAbsence: Bool
    let previousDominantCategory: NoxActivityCategory?
}
