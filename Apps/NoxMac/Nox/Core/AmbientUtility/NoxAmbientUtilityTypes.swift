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
import NoxShrineCore

nonisolated enum NoxContextualNudgeKind: String, Codable, Sendable {
    case unfinishedContinuity
    case recurringStructure
    case recoveryWindow
    case fragmentationLoop
    case decompressionSilence
    case ignoredStructure
}

nonisolated struct NoxContextualNudge: Identifiable, Equatable, Sendable {
    let id: String
    let kind: NoxContextualNudgeKind
    let line: String
    let detail: String?
    let confidence: Double
}

nonisolated struct NoxUnfinishedContinuityCandidate: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let detail: String
    let persistenceScore: Double
    let resumptions: Int
}

nonisolated struct NoxStructuralContinuityWeight: Equatable, Sendable {
    let subjectId: String
    let label: String
    let weight: Double
    let kind: NoxStructuralContinuityKind
}

nonisolated enum NoxStructuralContinuityKind: String, Sendable {
    case recurringReturn
    case sustainedEngagement
    case attentionSink
    case fragmentationLoop
    case stabilizingRhythm
    case unresolved
}

nonisolated struct NoxDecompressionState: Equatable, Sendable {
    let inDecompression: Bool
    let recoveryWindowOpen: Bool
    let passiveCollapseLoop: Bool
    let overloadAfterCoordination: Bool
    let confidence: Double
}

nonisolated struct NoxRecoveryWindowModel: Equatable, Sendable {
    let isOpen: Bool
    let label: String
    let detail: String
    let confidence: Double
}

nonisolated struct NoxInterventionReceptiveness: Equatable, Sendable {
    let score: Double
    let interruptionSensitive: Bool
    let deepFocusStable: Bool
    let recoveryOpen: Bool
    let fragmented: Bool
    let passiveDecompression: Bool

    var allowsIntervention: Bool { score >= 0.48 }
    var allowsNotification: Bool { score >= 0.52 }
    var allowsResurfacing: Bool { score >= 0.45 }
}

nonisolated struct NoxAdaptiveCalmnessProfile: Equatable, Sendable {
    let reflectionDensity: Double
    let resurfacingFrequency: Double
    let interventionProbability: Double
    let notificationProbability: Double
    let continuitySurfacingDepth: Double
    let preferSilence: Bool

    static let balanced = NoxAdaptiveCalmnessProfile(
        reflectionDensity: 1,
        resurfacingFrequency: 1,
        interventionProbability: 1,
        notificationProbability: 1,
        continuitySurfacingDepth: 1,
        preferSilence: false
    )

    var allowsResurfacing: Bool { !preferSilence && resurfacingFrequency >= 0.35 }
}

nonisolated struct NoxAttentionBalanceInsight: Equatable, Sendable {
    let label: String
    let detail: String
    let confidence: Double
}

nonisolated struct NoxAmbientNotificationCandidate: Identifiable, Equatable, Sendable {
    let id: String
    let kind: String
    let title: String
    let body: String
    let confidence: Double
}

nonisolated struct NoxAmbientUtilitySnapshot: Equatable, Sendable {
    let nudges: [NoxContextualNudge]
    let primaryNudge: NoxContextualNudge?
    let calmness: NoxAdaptiveCalmnessProfile
    let receptiveness: NoxInterventionReceptiveness
    let decompression: NoxDecompressionState
    let recoveryWindow: NoxRecoveryWindowModel
    let unfinishedThreads: [NoxUnfinishedContinuityCandidate]
    let structuralWeights: [NoxStructuralContinuityWeight]
    let attentionInsight: NoxAttentionBalanceInsight?
    let preferSilence: Bool
    let notificationCandidate: NoxAmbientNotificationCandidate?
    let refinedIntervention: NoxAmbientIntervention?
    let calibration: NoxAmbientUtilityCalibration

    static let empty = NoxAmbientUtilitySnapshot(
        nudges: [],
        primaryNudge: nil,
        calmness: .balanced,
        receptiveness: NoxInterventionReceptiveness(
            score: 0.5,
            interruptionSensitive: false,
            deepFocusStable: false,
            recoveryOpen: false,
            fragmented: false,
            passiveDecompression: false
        ),
        decompression: NoxDecompressionState(
            inDecompression: false,
            recoveryWindowOpen: false,
            passiveCollapseLoop: false,
            overloadAfterCoordination: false,
            confidence: 0
        ),
        recoveryWindow: NoxRecoveryWindowModel(isOpen: false, label: "", detail: "", confidence: 0),
        unfinishedThreads: [],
        structuralWeights: [],
        attentionInsight: nil,
        preferSilence: false,
        notificationCandidate: nil,
        refinedIntervention: nil,
        calibration: .neutral
    )
}

nonisolated struct NoxAmbientUtilityPreferences: Codable, Equatable, Sendable {
    var ambientNotificationsEnabled: Bool
    var systemState: NoxSystemStatePreferences

    static let `default` = NoxAmbientUtilityPreferences(
        ambientNotificationsEnabled: false,
        systemState: .default
    )

    init(
        ambientNotificationsEnabled: Bool = false,
        systemState: NoxSystemStatePreferences = .default
    ) {
        self.ambientNotificationsEnabled = ambientNotificationsEnabled
        self.systemState = systemState
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ambientNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .ambientNotificationsEnabled) ?? false
        systemState = try container.decodeIfPresent(NoxSystemStatePreferences.self, forKey: .systemState) ?? .default
    }

    private enum CodingKeys: String, CodingKey {
        case ambientNotificationsEnabled
        case systemState
    }
}
