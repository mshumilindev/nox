import Foundation

/// Universal foreground context — single model for pipeline, persistence subset, and dev explainability.
struct NoxAppContext: Equatable, Sendable {
    let observedAt: Date
    let appName: String
    let bundleId: String
    let processId: Int32?
    let windowTitle: String?
    let documentURL: String?
    let browserDomain: String?
    let browserPageTitle: String?
    let documentHint: String?
    let mediaHint: String?
    let fileTransferHint: String?
    let interactionShapeSummary: String
    let capabilities: NoxContextCapabilityProfile
    let observationStatuses: [NoxContextObservationStatus]
    let missingChannels: [NoxContextObservationChannel]
    let adapterIds: [String]
    let primaryAdapterId: String
    let sensitivity: NoxSensitivityLevel
    let evidenceItems: [NoxContextEvidenceItem]
    let resolution: NoxContextResolutionSummary
    let safeOutput: NoxSafeContextOutput
}

struct NoxContextResolutionSummary: Equatable, Sendable {
    let dominant: NoxContextCandidate?
    let secondary: [NoxContextCandidate]
    let staleIgnored: [NoxContextCandidate]
    let suppressed: [NoxContextCandidate]
    let dominanceScore: Double
    let reasons: [NoxContextReason]
    let supportingSignals: [String]
    let ignoredSignals: [String]
}
