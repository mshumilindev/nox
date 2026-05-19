import Foundation

enum NoxSemanticArcType: String, Codable, Sendable, CaseIterable {
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

enum NoxArcContinuityState: String, Codable, Sendable {
    case active
    case merging
    case fading
    case dormant
    case resurfaced
}

enum NoxArcEvolution: String, Codable, Sendable {
    case strengthening
    case stable
    case fragmenting
    case decaying
}

struct NoxSemanticArc: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let arcType: NoxSemanticArcType
    let continuityState: NoxArcContinuityState
    let evolution: NoxArcEvolution
    let spanCount: Int
    let sessionTouches: Int
    let firstSeenAt: Date
    let lastSeenAt: Date
    let strength: Double
    let detailLine: String?
}
