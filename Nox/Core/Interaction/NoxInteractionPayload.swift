import Foundation

enum NoxInteractionKind: String, Codable, Sendable {
    case typing
    case typingBurst
    case scroll
    case mouse
    case active
    case idle
}

struct InteractionPayload: Sendable, Equatable {
    let kind: NoxInteractionKind
    let intensity: Double?
}
