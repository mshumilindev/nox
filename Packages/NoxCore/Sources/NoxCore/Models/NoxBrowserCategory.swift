import Foundation

public enum NoxFusionLabel: String, Codable, Sendable {
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

public enum NoxBrowserCategory: String, Codable, Sendable {
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

public enum NoxAIWorkflowKind: String, Codable, Sendable {
    case passiveAIReading
    case promptWriting
    case iterativeWorkflow
    case waitingForGeneration
    case codeOriented
    case casualChat
    case researchHeavy
    case unknown
}
