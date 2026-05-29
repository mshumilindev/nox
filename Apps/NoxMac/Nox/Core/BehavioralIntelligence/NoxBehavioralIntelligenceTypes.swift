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

nonisolated enum NoxBehavioralPatternKind: String, Codable, Sendable, CaseIterable {
    case lateNightWorkCycle
    case overloadRecoveryOscillation
    case coordinationHeavyWeek
    case deepFocusStreak
    case fragmentedContext
    case creativeExploration
    case passiveDecompression
    case instabilityPhase
}

nonisolated struct NoxBehavioralSignature: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let kind: NoxBehavioralPatternKind
    let label: String
    let detail: String
    let confidence: Double
    let horizonDays: Int
    let evidence: [String]

    var isGated: Bool { confidence >= NoxPatternConfidenceModel.minimumDisplay }
}

nonisolated struct NoxExpectedRhythmWindow: Equatable, Sendable, Codable {
    let label: String
    let startHour: Int
    let endHour: Int
    let confidence: Double
}

nonisolated struct NoxExpectedRhythmModel: Equatable, Sendable, Codable {
    let likelyWorkWindows: [NoxExpectedRhythmWindow]
    let likelyRecoveryWindows: [NoxExpectedRhythmWindow]
    let expectedTransitions: [String]
    let continuityExpectations: [String]
    let confidence: Double
}

nonisolated struct NoxAdaptiveContinuityWeight: Equatable, Sendable, Codable {
    let threadId: String
    let weight: Double
    let reasons: [String]
}

nonisolated struct NoxTemporalRhythmInsight: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let label: String
    let detail: String
    let horizon: NoxTemporalRhythmHorizon
    let confidence: Double
}

nonisolated enum NoxTemporalRhythmHorizon: String, Codable, Sendable {
    case weekly
    case monthly
    case seasonal
}

nonisolated struct NoxLifeStructureCandidate: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let label: String
    let detail: String
    let confidence: Double
    let revisable: Bool
}

nonisolated struct NoxBehavioralDriftInsight: Equatable, Sendable, Codable {
    let label: String
    let detail: String
    let confidence: Double
    let driftKind: NoxBehavioralDriftKind
}

nonisolated enum NoxBehavioralDriftKind: String, Codable, Sendable {
    case rhythmInstability
    case prolongedQuiet
    case cadenceCollapse
    case sustainedDeviation
}

nonisolated struct NoxAmbientOrchestrationContext: Equatable, Sendable, Codable {
    let signals: [NoxOrchestrationSignal]
    let generatedAt: Date

    static let empty = NoxAmbientOrchestrationContext(signals: [], generatedAt: .distantPast)
}

nonisolated struct NoxOrchestrationSignal: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let kind: NoxOrchestrationSignalKind
    let level: Double
    let note: String
}

nonisolated enum NoxOrchestrationSignalKind: String, Codable, Sendable, CaseIterable {
    case highInterruptionSensitivity
    case deepFocusStability
    case overloadRiskElevation
    case recoveryOpportunityWindow
    case lowFragmentationWindow
    case returnAfterAbsence
}

nonisolated struct NoxBehavioralIntelligenceSnapshot: Equatable, Sendable {
    let signatures: [NoxBehavioralSignature]
    let expectations: NoxExpectedRhythmModel?
    let continuityWeights: [NoxAdaptiveContinuityWeight]
    let temporalRhythms: [NoxTemporalRhythmInsight]
    let lifeStructures: [NoxLifeStructureCandidate]
    let drift: NoxBehavioralDriftInsight?
    let orchestration: NoxAmbientOrchestrationContext
    let enrichmentNotes: [String]
    let prioritizedThreadIds: [String]
    let prioritizedArcIds: [String]
    let recommendedIntervention: NoxAmbientIntervention?

    static let empty = NoxBehavioralIntelligenceSnapshot(
        signatures: [],
        expectations: nil,
        continuityWeights: [],
        temporalRhythms: [],
        lifeStructures: [],
        drift: nil,
        orchestration: .empty,
        enrichmentNotes: [],
        prioritizedThreadIds: [],
        prioritizedArcIds: [],
        recommendedIntervention: nil
    )
}
