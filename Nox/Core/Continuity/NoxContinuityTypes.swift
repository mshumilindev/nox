import Foundation

enum NoxContinuitySemanticType: String, Codable, Sendable, CaseIterable {
    case aiDevelopment
    case research
    case travelPlanning
    case writing
    case development
    case fragmentedWorkflow
    case passiveViewing
    case privateContext
    case sensitiveContext
    case general
}

enum NoxContinuityStatus: String, Codable, Sendable {
    case active
    case paused
    case resumed
    case fading
    case dormant
}

enum NoxContinuityDecayState: String, Codable, Sendable {
    case active
    case fading
    case dormant
    case archived
}

nonisolated struct NoxContinuityMatchComponent: Equatable, Sendable, Codable {
    let name: String
    let score: Double
    let detail: String
}

struct NoxContinuityMatchResult: Equatable, Sendable {
    let threadId: String
    let totalScore: Double
    let components: [NoxContinuityMatchComponent]
    let isResumption: Bool
}

struct NoxContinuityResurfacing: Equatable, Sendable {
    let threadId: String
    let primaryText: String
    let secondaryText: String?
    let confidence: Double
    let timestamp: Date
}
