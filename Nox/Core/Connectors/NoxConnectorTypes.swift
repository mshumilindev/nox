import Foundation

enum NoxConnectorKind: String, Codable, CaseIterable, Sendable {
    case calendar
    case communication
    case cadence
    case transition
    case recovery
}

nonisolated struct NoxConnectorPreferences: Codable, Equatable, Sendable {
    var calendarEnabled: Bool
    var communicationPressureEnabled: Bool
    var continuityEnrichmentPaused: Bool

    static let `default` = NoxConnectorPreferences(
        calendarEnabled: true,
        communicationPressureEnabled: true,
        continuityEnrichmentPaused: false
    )
}

struct NoxGeneralizedSignal: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let kind: NoxConnectorKind
    let label: String
    let confidence: Double
    let observedAt: Date
}

struct NoxPressureSignal: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let kind: NoxConnectorKind
    let label: String
    let level: NoxPressureLevel
    let confidence: Double
    let observedAt: Date
}

enum NoxPressureLevel: String, Codable, Sendable {
    case low
    case moderate
    case elevated
}

nonisolated struct NoxCadencePattern: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let label: String
    let confidence: Double
    let horizonDays: Int
}

struct NoxTransitionEvent: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let kind: NoxTransitionKind
    let label: String
    let confidence: Double
    let observedAt: Date
}

enum NoxTransitionKind: String, Codable, Sendable {
    case enteringDeepWork
    case exitingSustainedFocus
    case beginningRecovery
    case returningAfterAbsence
    case abruptFragmentation
    case contextCollapse
    case workToPassiveMedia
    case travelLikeShift
}

struct NoxOverloadSignal: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let label: String
    let confidence: Double
    let observedAt: Date
}

struct NoxConnectorExplainabilitySummary: Equatable, Sendable {
    let contributedCategories: [NoxConnectorKind]
    let collectedSummary: String
    let notCollectedSummary: String
    let provenanceLines: [String]
}

struct NoxConnectorContinuitySnapshot: Equatable, Sendable {
    let generalizedSignals: [NoxGeneralizedSignal]
    let pressureSignals: [NoxPressureSignal]
    let cadencePatterns: [NoxCadencePattern]
    let transitions: [NoxTransitionEvent]
    let overloadSignals: [NoxOverloadSignal]
    let enrichmentNotes: [String]
    let explainability: NoxConnectorExplainabilitySummary
    let intervention: NoxAmbientIntervention?

    static let empty = NoxConnectorContinuitySnapshot(
        generalizedSignals: [],
        pressureSignals: [],
        cadencePatterns: [],
        transitions: [],
        overloadSignals: [],
        enrichmentNotes: [],
        explainability: .empty,
        intervention: nil
    )
}

extension NoxConnectorExplainabilitySummary {
    static let empty = NoxConnectorExplainabilitySummary(
        contributedCategories: [],
        collectedSummary: "No connector signals in this refresh.",
        notCollectedSummary: "Email bodies, message text, and meeting titles are not stored.",
        provenanceLines: []
    )
}

struct NoxAmbientIntervention: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let detail: String
    let kind: NoxInterventionKind
    let observedAt: Date
}

enum NoxInterventionKind: String, Codable, Sendable {
    case resurfacingAfterReturn
    case fragmentedDayAck
    case recoveryAwareShift
    case lateNightCadence
}
