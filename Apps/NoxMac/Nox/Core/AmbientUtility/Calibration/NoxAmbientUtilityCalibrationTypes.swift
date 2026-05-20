import Foundation
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore

nonisolated struct NoxAmbientTrustState: Codable, Equatable, Sendable {
    var trustScore: Double
    var notificationFatigue: Double
    var continuityGravity: [String: Double]
    var deliveredNotificationCount: Int
    var suppressedUtilityCount: Int
    var poorTimingEventCount: Int
    var lastCalibrationAt: Date?

    static let initial = NoxAmbientTrustState(
        trustScore: 0.72,
        notificationFatigue: 0,
        continuityGravity: [:],
        deliveredNotificationCount: 0,
        suppressedUtilityCount: 0,
        poorTimingEventCount: 0,
        lastCalibrationAt: nil
    )
}

nonisolated enum NoxDecompressionQualityKind: String, Codable, Sendable {
    case healthyRecovery
    case passiveCollapse
    case fragmentedEscapism
    case restorativeContinuity
    case overloadLoop
    case neutral
}

nonisolated struct NoxRecoveryQualityModel: Equatable, Sendable {
    let kind: NoxDecompressionQualityKind
    let suppressResurfacing: Bool
    let preferSilence: Bool
    let allowGentleContinuity: Bool
    let confidence: Double
}

nonisolated struct NoxExperientialPriority: Equatable, Sendable {
    let subjectId: String
    let label: String
    let significance: Double
    let stabilizesRhythm: Bool
}

nonisolated struct NoxAmbientUtilityCalibration: Equatable, Sendable {
    let trustScore: Double
    let notificationFatigue: Double
    let interruptionCost: Double
    let globalRestraint: Double
    let preferSilence: Bool
    let recoveryQuality: NoxRecoveryQualityModel
    let prioritizedThreadIds: [String]
    let prioritizedArcIds: [String]
    let experientialPriorities: [NoxExperientialPriority]

    static let neutral = NoxAmbientUtilityCalibration(
        trustScore: 0.72,
        notificationFatigue: 0,
        interruptionCost: 0.4,
        globalRestraint: 1,
        preferSilence: false,
        recoveryQuality: NoxRecoveryQualityModel(
            kind: .neutral,
            suppressResurfacing: false,
            preferSilence: false,
            allowGentleContinuity: true,
            confidence: 0.5
        ),
        prioritizedThreadIds: [],
        prioritizedArcIds: [],
        experientialPriorities: []
    )
}
