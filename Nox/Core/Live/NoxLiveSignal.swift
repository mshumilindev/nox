import Foundation

enum NoxLiveSignalKind: String, Sendable {
    case awareness
    case app
    case window
    case idle
    case session
    case system
    case permission
}

enum NoxLiveSignalLifecycle: Equatable, Sendable {
    case persistent
    /// Expires after `ttl` seconds from `timestamp`.
    case transient(TimeInterval)
}

struct NoxLiveSignal: Identifiable, Equatable, Sendable {
    let id: String
    let timestamp: Date
    let text: String
    let kind: NoxLiveSignalKind
    let lifecycle: NoxLiveSignalLifecycle

    init(
        id: String,
        timestamp: Date,
        text: String,
        kind: NoxLiveSignalKind,
        lifecycle: NoxLiveSignalLifecycle = .persistent
    ) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
        self.kind = kind
        self.lifecycle = lifecycle
    }

    var isExpired: Bool {
        guard case .transient(let ttl) = lifecycle else { return false }
        return Date().timeIntervalSince(timestamp) > ttl
    }

    var isStale: Bool {
        guard case .transient(let ttl) = lifecycle else { return false }
        return Date().timeIntervalSince(timestamp) > ttl * 0.6
    }

    static let limitedObservationText = "App awareness only"
}
