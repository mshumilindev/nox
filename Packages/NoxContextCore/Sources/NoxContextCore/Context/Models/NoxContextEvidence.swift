import Foundation
import NoxCore

// MARK: - Evidence bundle

public struct NoxContextEvidence: Equatable, Sendable {
    public let appIdentity: NoxAppIdentityEvidence
    public let windowIdentity: NoxWindowIdentityEvidence
    public let contentIdentity: NoxContentIdentityEvidence
    public let activity: NoxActivityEvidence
    public let capability: NoxCapabilityEvidence
    public let semantic: NoxSemanticEvidenceBundle
    public let safeOutput: NoxSafeContextOutput
    public let evaluatedAt: Date
    /// Universal foreground context (Iteration 6A).
    public let appContext: NoxAppContext
    /// Flat evidence log for debugging and explainability.
    public let evidenceItems: [NoxContextEvidenceItem]
}

// MARK: - Identity

public struct NoxAppIdentityEvidence: Equatable, Sendable {
    public let appName: String
    public let bundleId: String
    public let processId: Int32?
    public let executablePath: String?
    public let appFamily: NoxAppFamily
}

public enum NoxAppFamily: String, Codable, Sendable {
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

public struct NoxWindowIdentityEvidence: Equatable, Sendable {
    public let activeWindowTitle: String?
    public let windowRole: String?
    public let windowSubrole: String?
    public let isFullscreen: Bool
    public let isMinimized: Bool
    public let focusedElementRole: String?
}

public struct NoxContentIdentityEvidence: Equatable, Sendable {
    public let contextTitle: String?
    public let contextSubtitle: String?
    public let documentTitle: String?
    public let projectOrWorkspaceTitle: String?
    public let activeResourceName: String?
    public let domain: String?
    public let mediaTitle: String?
    public let fileName: String?
    public let conversationOrChannelName: String?
}

// MARK: - Activity

public struct NoxActivityEvidence: Equatable, Sendable {
    public let typingDensity: Double
    public let scrollDensity: Double
    public let pointerActivityLevel: Double
    public let idleSeconds: TimeInterval
    public let stableDurationSeconds: TimeInterval
    public let appSwitchCountRecent: Int
    public let isInteractionBurst: Bool
    public let passiveDurationSeconds: TimeInterval
    public let isUserIdle: Bool
    public let recentTransitionSummary: String?
}

// MARK: - Capability

public struct NoxCapabilityEvidence: Equatable, Sendable {
    public let acquisitionLevel: NoxContextAcquisitionLevel
    public let adapterId: String
    public let sourceConfidence: Double
    public let extractionFreshnessSeconds: TimeInterval
    public let permissionsRequired: [String]
    public let permissionsMissing: [String]
    public let adapterReliability: Double
}

// MARK: - Semantic

public struct NoxSemanticEvidenceBundle: Equatable, Sendable {
    public let candidates: [NoxContextCandidate]
    public let dominant: NoxContextCandidate?
    public let secondary: [NoxContextCandidate]
    public let staleIgnored: [NoxContextCandidate]
    public let dominanceScore: Double
    public let sensitivityLevel: NoxSensitivityLevel
    public let reasons: [NoxContextReason]
    public let supportingSignals: [String]
    public let ignoredSignals: [String]
}

public struct NoxContextCandidate: Equatable, Sendable, Identifiable {
    public let id: String
    public let contextType: NoxDominantContextType
    public let confidence: Double
    public let dominanceWeight: Double
    public let sourceAdapterId: String
    public let signalNames: [String]

    public init(
        id: String,
        contextType: NoxDominantContextType,
        confidence: Double,
        dominanceWeight: Double,
        sourceAdapterId: String,
        signalNames: [String]
    ) {
        self.id = id
        self.contextType = contextType
        self.confidence = confidence
        self.dominanceWeight = dominanceWeight
        self.sourceAdapterId = sourceAdapterId
        self.signalNames = signalNames
    }
}

public struct NoxContextReason: Equatable, Sendable {
    public let category: String
    public let detail: String
    public let weight: Double
}

// MARK: - Safe output

public struct NoxSafeContextOutput: Equatable, Sendable {
    public let displayLabel: String
    public let subtitle: String?
    public let dominantContextType: NoxDominantContextType
    public let secondaryContextTypes: [NoxDominantContextType]
    public let detailsRedacted: Bool
    public let redactionReason: String?
}

// MARK: - Adapter input

public struct NoxContextAdapterInput: Equatable, Sendable {
    public let snapshot: NoxActivitySnapshot
    public let capabilities: NoxContextCapabilityProfile
    public let metrics: NoxInteractionMetrics
    public let activityCategory: NoxActivityCategory
    public let sanitizedTitle: String?
    public let domain: String?
    public let stableDurationSeconds: TimeInterval
    public let recentSwitchCount: Int
    public let sensitivityLevel: NoxSensitivityLevel

    public init(
        snapshot: NoxActivitySnapshot,
        capabilities: NoxContextCapabilityProfile,
        metrics: NoxInteractionMetrics,
        activityCategory: NoxActivityCategory,
        sanitizedTitle: String?,
        domain: String?,
        stableDurationSeconds: TimeInterval,
        recentSwitchCount: Int,
        sensitivityLevel: NoxSensitivityLevel
    ) {
        self.snapshot = snapshot
        self.capabilities = capabilities
        self.metrics = metrics
        self.activityCategory = activityCategory
        self.sanitizedTitle = sanitizedTitle
        self.domain = domain
        self.stableDurationSeconds = stableDurationSeconds
        self.recentSwitchCount = recentSwitchCount
        self.sensitivityLevel = sensitivityLevel
    }
}

public struct NoxContextAdapterEvidence: Equatable, Sendable {
    public let adapterId: String
    public let reliability: Double
    public let candidates: [NoxContextCandidate]
    public let reasons: [NoxContextReason]
    public let supportingSignals: [String]
}
