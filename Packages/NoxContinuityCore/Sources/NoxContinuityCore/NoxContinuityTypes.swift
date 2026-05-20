import Foundation
import NoxSemanticCore
import NoxMemoryCore
import NoxContextCore
import NoxCore

public enum NoxContinuitySemanticType: String, Codable, Sendable, CaseIterable {
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

public enum NoxContinuityStatus: String, Codable, Sendable {
    case active
    case paused
    case resumed
    case fading
    case dormant
}

public enum NoxContinuityDecayState: String, Codable, Sendable {
    case active
    case fading
    case dormant
    case archived
}

public nonisolated struct NoxContinuityMatchComponent: Equatable, Sendable, Codable {
    public let name: String
    public let score: Double
    public let detail: String

    public init(name: String, score: Double, detail: String) {
        self.name = name
        self.score = score
        self.detail = detail
    }
}

public struct NoxContinuityMatchResult: Equatable, Sendable {
    public let threadId: String
    public let totalScore: Double
    public let components: [NoxContinuityMatchComponent]
    public let isResumption: Bool

    public init(threadId: String, totalScore: Double, components: [NoxContinuityMatchComponent], isResumption: Bool) {
        self.threadId = threadId
        self.totalScore = totalScore
        self.components = components
        self.isResumption = isResumption
    }
}

public struct NoxContinuityResurfacing: Equatable, Sendable {
    public let threadId: String
    public let primaryText: String
    public let secondaryText: String?
    public let confidence: Double
    public let timestamp: Date

    public init(
        threadId: String,
        primaryText: String,
        secondaryText: String?,
        confidence: Double,
        timestamp: Date
    ) {
        self.threadId = threadId
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.confidence = confidence
        self.timestamp = timestamp
    }
}
