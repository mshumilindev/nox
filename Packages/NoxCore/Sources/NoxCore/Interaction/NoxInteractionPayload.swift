import Foundation

public enum NoxInteractionKind: String, Codable, Sendable {
    case typing
    case typingBurst
    case scroll
    case mouse
    case active
    case idle
}

public struct InteractionPayload: Sendable, Equatable {
    public let kind: NoxInteractionKind
    public let intensity: Double?

    public init(kind: NoxInteractionKind, intensity: Double? = nil) {
        self.kind = kind
        self.intensity = intensity
    }
}
