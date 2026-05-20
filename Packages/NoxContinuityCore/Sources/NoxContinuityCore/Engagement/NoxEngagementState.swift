import Foundation
import NoxSemanticCore
import NoxMemoryCore
import NoxContextCore
import NoxCore

public enum NoxEngagementPhase: String, Sendable {
    case rawForeground
    case transientTraversal
    case softStabilized
    case hardStabilized
    case wandering
}

public struct NoxEngagementState: Equatable, Sendable {
    public let phase: NoxEngagementPhase
    public let snapshot: NoxActivitySnapshot
    public let foregroundStartedAt: Date
    public let observedAt: Date
    public let foregroundDuration: TimeInterval
    public let interactionStrength: Double
    public let intent: NoxForegroundIntent
    public let debugReason: String

    public var isTransient: Bool { phase == .transientTraversal }
    public var isSoftStabilized: Bool { phase == .softStabilized || phase == .hardStabilized }
    public var isHardStabilized: Bool { phase == .hardStabilized }
}

public struct NoxForegroundIntent: Equatable, Sendable {
    let continuityWeight: Double
    let softThreshold: TimeInterval
    let hardThreshold: TimeInterval
    let requiresLongerStabilization: Bool

    static let standard = NoxForegroundIntent(
        continuityWeight: 0.55,
        softThreshold: 2.0,
        hardThreshold: 7.0,
        requiresLongerStabilization: false
    )
}

public struct NoxStabilizationDecision: Equatable, Sendable {
    public let state: NoxEngagementState
    public let becameSoft: Bool
    public let becameHard: Bool
    public let closedTransient: NoxEngagementState?
    public let wanderingState: NoxEngagementState?
    public let continuityMerge: NoxContinuityMerge?
}

public struct NoxContinuityMerge: Equatable, Sendable {
    public let bundleId: String
    public let absorbedTraversalCount: Int
    public let totalTraversalSeconds: TimeInterval

    public init(bundleId: String, absorbedTraversalCount: Int, totalTraversalSeconds: TimeInterval) {
        self.bundleId = bundleId
        self.absorbedTraversalCount = absorbedTraversalCount
        self.totalTraversalSeconds = totalTraversalSeconds
    }
}
