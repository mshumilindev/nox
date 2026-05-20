import Foundation

enum NoxEngagementPhase: String, Sendable {
    case rawForeground
    case transientTraversal
    case softStabilized
    case hardStabilized
    case wandering
}

struct NoxEngagementState: Equatable, Sendable {
    let phase: NoxEngagementPhase
    let snapshot: NoxActivitySnapshot
    let foregroundStartedAt: Date
    let observedAt: Date
    let foregroundDuration: TimeInterval
    let interactionStrength: Double
    let intent: NoxForegroundIntent
    let debugReason: String

    var isTransient: Bool { phase == .transientTraversal }
    var isSoftStabilized: Bool { phase == .softStabilized || phase == .hardStabilized }
    var isHardStabilized: Bool { phase == .hardStabilized }
}

struct NoxForegroundIntent: Equatable, Sendable {
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

struct NoxStabilizationDecision: Equatable, Sendable {
    let state: NoxEngagementState
    let becameSoft: Bool
    let becameHard: Bool
    let closedTransient: NoxEngagementState?
    let wanderingState: NoxEngagementState?
    let continuityMerge: NoxContinuityMerge?
}

struct NoxContinuityMerge: Equatable, Sendable {
    let bundleId: String
    let absorbedTraversalCount: Int
    let totalTraversalSeconds: TimeInterval
}
