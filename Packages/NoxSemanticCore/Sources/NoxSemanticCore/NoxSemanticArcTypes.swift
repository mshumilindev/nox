import Foundation
import NoxCore
import NoxContextCore

public enum NoxSemanticArcType: String, Codable, Sendable, CaseIterable {
    case aiWorkflow
    case development
    case research
    case travelPlanning
    case creativeExploration
    case communication
    case passiveMedia
    case fragmentedAttention
    case general
}

public enum NoxArcContinuityState: String, Codable, Sendable {
    case active
    case merging
    case fading
    case dormant
    case resurfaced
}

public enum NoxArcEvolution: String, Codable, Sendable {
    case strengthening
    case stable
    case fragmenting
    case decaying
}

public struct NoxSemanticArc: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let arcType: NoxSemanticArcType
    public let continuityState: NoxArcContinuityState
    public let evolution: NoxArcEvolution
    public let spanCount: Int
    public let sessionTouches: Int
    public let firstSeenAt: Date
    public let lastSeenAt: Date
    public let strength: Double
    public let detailLine: String?

    public init(
        id: String,
        label: String,
        arcType: NoxSemanticArcType,
        continuityState: NoxArcContinuityState,
        evolution: NoxArcEvolution,
        spanCount: Int,
        sessionTouches: Int,
        firstSeenAt: Date,
        lastSeenAt: Date,
        strength: Double,
        detailLine: String?
    ) {
        self.id = id
        self.label = label
        self.arcType = arcType
        self.continuityState = continuityState
        self.evolution = evolution
        self.spanCount = spanCount
        self.sessionTouches = sessionTouches
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
        self.strength = strength
        self.detailLine = detailLine
    }
}
