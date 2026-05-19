import Foundation

// MARK: - Evidence bundle

struct NoxContextEvidence: Equatable, Sendable {
    let appIdentity: NoxAppIdentityEvidence
    let windowIdentity: NoxWindowIdentityEvidence
    let contentIdentity: NoxContentIdentityEvidence
    let activity: NoxActivityEvidence
    let capability: NoxCapabilityEvidence
    let semantic: NoxSemanticEvidenceBundle
    let safeOutput: NoxSafeContextOutput
    let evaluatedAt: Date
    /// Universal foreground context (Iteration 6A).
    let appContext: NoxAppContext
    /// Flat evidence log for debugging and explainability.
    let evidenceItems: [NoxContextEvidenceItem]
}

// MARK: - Identity

struct NoxAppIdentityEvidence: Equatable, Sendable {
    let appName: String
    let bundleId: String
    let processId: Int32?
    let executablePath: String?
    let appFamily: NoxAppFamily
}

enum NoxAppFamily: String, Codable, Sendable {
    case browser
    case editor
    case terminal
    case mediaPlayer
    case communication
    case creative
    case document
    case fileManager
    case game
    case utility
    case unknown
}

struct NoxWindowIdentityEvidence: Equatable, Sendable {
    let activeWindowTitle: String?
    let windowRole: String?
    let windowSubrole: String?
    let isFullscreen: Bool
    let isMinimized: Bool
    let focusedElementRole: String?
}

struct NoxContentIdentityEvidence: Equatable, Sendable {
    let contextTitle: String?
    let contextSubtitle: String?
    let documentTitle: String?
    let projectOrWorkspaceTitle: String?
    let activeResourceName: String?
    let domain: String?
    let mediaTitle: String?
    let fileName: String?
    let conversationOrChannelName: String?
}

// MARK: - Activity

struct NoxActivityEvidence: Equatable, Sendable {
    let typingDensity: Double
    let scrollDensity: Double
    let pointerActivityLevel: Double
    let idleSeconds: TimeInterval
    let stableDurationSeconds: TimeInterval
    let appSwitchCountRecent: Int
    let isInteractionBurst: Bool
    let passiveDurationSeconds: TimeInterval
    let isUserIdle: Bool
    let recentTransitionSummary: String?
}

// MARK: - Capability

struct NoxCapabilityEvidence: Equatable, Sendable {
    let acquisitionLevel: NoxContextAcquisitionLevel
    let adapterId: String
    let sourceConfidence: Double
    let extractionFreshnessSeconds: TimeInterval
    let permissionsRequired: [String]
    let permissionsMissing: [String]
    let adapterReliability: Double
}

// MARK: - Semantic

struct NoxSemanticEvidenceBundle: Equatable, Sendable {
    let candidates: [NoxContextCandidate]
    let dominant: NoxContextCandidate?
    let secondary: [NoxContextCandidate]
    let staleIgnored: [NoxContextCandidate]
    let dominanceScore: Double
    let sensitivityLevel: NoxSensitivityLevel
    let reasons: [NoxContextReason]
    let supportingSignals: [String]
    let ignoredSignals: [String]
}

struct NoxContextCandidate: Equatable, Sendable, Identifiable {
    let id: String
    let contextType: NoxDominantContextType
    let confidence: Double
    let dominanceWeight: Double
    let sourceAdapterId: String
    let signalNames: [String]
}

struct NoxContextReason: Equatable, Sendable {
    let category: String
    let detail: String
    let weight: Double
}

// MARK: - Safe output

struct NoxSafeContextOutput: Equatable, Sendable {
    let displayLabel: String
    let subtitle: String?
    let dominantContextType: NoxDominantContextType
    let secondaryContextTypes: [NoxDominantContextType]
    let detailsRedacted: Bool
    let redactionReason: String?
}

// MARK: - Adapter input

struct NoxContextAdapterInput: Equatable, Sendable {
    let snapshot: NoxActivitySnapshot
    let capabilities: NoxContextCapabilityProfile
    let metrics: NoxInteractionMetrics
    let activityCategory: NoxActivityCategory
    let sanitizedTitle: String?
    let domain: String?
    let stableDurationSeconds: TimeInterval
    let recentSwitchCount: Int
    let sensitivityLevel: NoxSensitivityLevel
}

struct NoxContextAdapterEvidence: Equatable, Sendable {
    let adapterId: String
    let reliability: Double
    let candidates: [NoxContextCandidate]
    let reasons: [NoxContextReason]
    let supportingSignals: [String]
}
