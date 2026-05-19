import Foundation

enum NoxQuietMode: String, Codable, Sendable, CaseIterable {
    case none
    case quietEvening
    case privateSession
    case lowAwareness
    case pauseContinuity

    var title: String {
        switch self {
        case .none: "Off"
        case .quietEvening: "Quiet evening"
        case .privateSession: "Private session"
        case .lowAwareness: "Low awareness"
        case .pauseContinuity: "Pause continuity"
        }
    }

    var detail: String {
        switch self {
        case .none:
            "Normal ambient observation."
        case .quietEvening:
            "Softer signals and fewer resurfacing moments."
        case .privateSession:
            "Observation continues lightly; semantic memory pauses."
        case .lowAwareness:
            "App-level awareness only; deeper context waits."
        case .pauseContinuity:
            "Continuity threads pause; recent context stays local."
        }
    }
}

nonisolated struct NoxAmbientPauseState: Codable, Equatable, Sendable {
    var observationPaused: Bool
    var semanticMemoryPaused: Bool
    var continuityPaused: Bool
    var quietMode: NoxQuietMode

    static let active = NoxAmbientPauseState(
        observationPaused: false,
        semanticMemoryPaused: false,
        continuityPaused: false,
        quietMode: .none
    )

    var isFullyPaused: Bool {
        observationPaused && semanticMemoryPaused
    }
}
