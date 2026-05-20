import Foundation
import NoxCore

/// Universal foreground context — single model for pipeline, persistence subset, and dev explainability.
public struct NoxAppContext: Equatable, Sendable {
    public let observedAt: Date
    public let appName: String
    public let bundleId: String
    public let processId: Int32?
    public let windowTitle: String?
    public let documentURL: String?
    public let browserDomain: String?
    public let browserPageTitle: String?
    public let documentHint: String?
    public let mediaHint: String?
    public let fileTransferHint: String?
    public let interactionShapeSummary: String
    public let capabilities: NoxContextCapabilityProfile
    public let observationStatuses: [NoxContextObservationStatus]
    public let missingChannels: [NoxContextObservationChannel]
    public let adapterIds: [String]
    public let primaryAdapterId: String
    public let sensitivity: NoxSensitivityLevel
    public let evidenceItems: [NoxContextEvidenceItem]
    public let resolution: NoxContextResolutionSummary
    public let safeOutput: NoxSafeContextOutput
}

public struct NoxContextResolutionSummary: Equatable, Sendable {
    public let dominant: NoxContextCandidate?
    public let secondary: [NoxContextCandidate]
    public let staleIgnored: [NoxContextCandidate]
    public let suppressed: [NoxContextCandidate]
    public let dominanceScore: Double
    public let reasons: [NoxContextReason]
    public let supportingSignals: [String]
    public let ignoredSignals: [String]
}
