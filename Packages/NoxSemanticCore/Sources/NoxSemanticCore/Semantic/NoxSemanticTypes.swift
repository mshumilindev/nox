import Foundation
import NoxCore
import NoxContextCore

public enum NoxSemanticState: String, Codable, CaseIterable, Sendable {
    case reading
    case writing
    case passiveConsumption
    case activeInteraction
    case waiting
    case fragmentedInteraction
    case sustainedInteraction
    case comparisonActivity
    case reviewing
    case unknown
}

public struct NoxSemanticReason: Equatable, Sendable {
    public let signal: String
    public let detail: String

    public init(signal: String, detail: String) {
        self.signal = signal
        self.detail = detail
    }
}

public struct NoxSemanticInference: Equatable, Sendable {
    public let state: NoxSemanticState
    public let confidence: Double
    public let displayPhrase: String
    public let reasons: [NoxSemanticReason]
    public let fusionLabel: NoxFusionLabel
    public let fusionConfidence: Double
    public let fusionPhrase: String
    public let sensitivityLevel: NoxSensitivityLevel
    public let browserCategory: NoxBrowserCategory
    public let aiWorkflow: NoxAIWorkflowKind?
    public let aiWorkflowPhrase: String?
    public let shouldSurface: Bool

    public init(
        state: NoxSemanticState,
        confidence: Double,
        displayPhrase: String,
        reasons: [NoxSemanticReason],
        fusionLabel: NoxFusionLabel,
        fusionConfidence: Double,
        fusionPhrase: String,
        sensitivityLevel: NoxSensitivityLevel,
        browserCategory: NoxBrowserCategory,
        aiWorkflow: NoxAIWorkflowKind?,
        aiWorkflowPhrase: String?,
        shouldSurface: Bool
    ) {
        self.state = state
        self.confidence = confidence
        self.displayPhrase = displayPhrase
        self.reasons = reasons
        self.fusionLabel = fusionLabel
        self.fusionConfidence = fusionConfidence
        self.fusionPhrase = fusionPhrase
        self.sensitivityLevel = sensitivityLevel
        self.browserCategory = browserCategory
        self.aiWorkflow = aiWorkflow
        self.aiWorkflowPhrase = aiWorkflowPhrase
        self.shouldSurface = shouldSurface
    }

    public static let hidden = NoxSemanticInference(
        state: .unknown,
        confidence: 0,
        displayPhrase: "",
        reasons: [],
        fusionLabel: .unknown,
        fusionConfidence: 0,
        fusionPhrase: "",
        sensitivityLevel: .normal,
        browserCategory: .unknown,
        aiWorkflow: nil,
        aiWorkflowPhrase: nil,
        shouldSurface: false
    )
}

public struct NoxSemanticContext: Equatable, Sendable {
    public let capabilities: NoxCapabilityState
    public let bundleId: String?
    public let appName: String?
    public let windowTitle: String?
    public let domain: String?
    public let metrics: NoxInteractionMetrics
    public let timeInCurrentApp: TimeInterval
    public let recentSwitchCount: Int
    public let isUserIdle: Bool
    public let idleSeconds: TimeInterval
    public let nearbyBundleIds: [String]
    public let focusHint: NoxFocusModeHint
    public let hourOfDay: Int
    public let observationContinuitySeconds: TimeInterval
    public let browserCategory: NoxBrowserCategory
    public let dominantContextType: NoxDominantContextType?
    public let dominantContextConfidence: Double
    public let fragmentationSwitchCount: Int

    public init(
        capabilities: NoxCapabilityState,
        bundleId: String?,
        appName: String?,
        windowTitle: String?,
        domain: String?,
        metrics: NoxInteractionMetrics,
        timeInCurrentApp: TimeInterval,
        recentSwitchCount: Int,
        isUserIdle: Bool,
        idleSeconds: TimeInterval,
        nearbyBundleIds: [String],
        focusHint: NoxFocusModeHint,
        hourOfDay: Int,
        observationContinuitySeconds: TimeInterval,
        browserCategory: NoxBrowserCategory,
        dominantContextType: NoxDominantContextType?,
        dominantContextConfidence: Double,
        fragmentationSwitchCount: Int
    ) {
        self.capabilities = capabilities
        self.bundleId = bundleId
        self.appName = appName
        self.windowTitle = windowTitle
        self.domain = domain
        self.metrics = metrics
        self.timeInCurrentApp = timeInCurrentApp
        self.recentSwitchCount = recentSwitchCount
        self.isUserIdle = isUserIdle
        self.idleSeconds = idleSeconds
        self.nearbyBundleIds = nearbyBundleIds
        self.focusHint = focusHint
        self.hourOfDay = hourOfDay
        self.observationContinuitySeconds = observationContinuitySeconds
        self.browserCategory = browserCategory
        self.dominantContextType = dominantContextType
        self.dominantContextConfidence = dominantContextConfidence
        self.fragmentationSwitchCount = fragmentationSwitchCount
    }
}
