import Foundation

enum NoxSemanticState: String, Codable, CaseIterable, Sendable {
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

enum NoxSensitivityLevel: String, Codable, Sendable {
    case normal
    case personal
    case sensitive
    case privateContext
}

enum NoxFusionLabel: String, Codable, Sendable {
    case likelyWorkRelated
    case possiblyPersonal
    case likelyResearch
    case likelyTravelPlanning
    case likelyShopping
    case likelyPassiveEntertainment
    case likelyAIAssistedWork
    case likelyFileTransfer
    case likelyGaming
    case likelyCreativeWork
    case likelyCommunication
    case likelyInteractiveBrowsing
    case unknown
}

enum NoxBrowserCategory: String, Codable, Sendable {
    case development
    case research
    case travel
    case shopping
    case entertainment
    case communication
    case social
    case reference
    case recipes
    case reviews
    case aiWorkflow
    case sensitive
    case privateBrowsing
    case ambiguous
    case unknown
}

enum NoxAIWorkflowKind: String, Codable, Sendable {
    case passiveAIReading
    case promptWriting
    case iterativeWorkflow
    case waitingForGeneration
    case codeOriented
    case casualChat
    case researchHeavy
    case unknown
}

struct NoxSemanticReason: Equatable, Sendable {
    let signal: String
    let detail: String
}

struct NoxSemanticInference: Equatable, Sendable {
    let state: NoxSemanticState
    let confidence: Double
    let displayPhrase: String
    let reasons: [NoxSemanticReason]
    let fusionLabel: NoxFusionLabel
    let fusionConfidence: Double
    let fusionPhrase: String
    let sensitivityLevel: NoxSensitivityLevel
    let browserCategory: NoxBrowserCategory
    let aiWorkflow: NoxAIWorkflowKind?
    let aiWorkflowPhrase: String?
    let shouldSurface: Bool

    static let hidden = NoxSemanticInference(
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

struct NoxSemanticContext: Equatable, Sendable {
    let capabilities: NoxCapabilityState
    let bundleId: String?
    let appName: String?
    let windowTitle: String?
    let domain: String?
    let metrics: NoxInteractionMetrics
    let timeInCurrentApp: TimeInterval
    let recentSwitchCount: Int
    let isUserIdle: Bool
    let idleSeconds: TimeInterval
    let nearbyBundleIds: [String]
    let focusHint: NoxFocusModeHint
    let hourOfDay: Int
    let observationContinuitySeconds: TimeInterval
    let browserCategory: NoxBrowserCategory
    let dominantContextType: NoxDominantContextType?
    let dominantContextConfidence: Double
    let fragmentationSwitchCount: Int
}
