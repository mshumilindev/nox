import Foundation

enum NoxEventType: String, Codable, Sendable {
    case appChanged = "app.changed"
    case windowChanged = "window.changed"
    case userIdleStarted = "user.idle.started"
    case userIdleEnded = "user.idle.ended"
    case sessionStarted = "session.started"
    case sessionEnded = "session.ended"
    case presenceChanged = "presence.changed"
    case permissionChanged = "permission.changed"
    case systemWake = "system.wake"
    case systemSleep = "system.sleep"
    case screenLocked = "screen.locked"
    case screenUnlocked = "screen.unlocked"
    case typingStarted = "typing.started"
    case typingBurst = "typing.burst"
    case scrollActivity = "scroll.activity"
    case mouseActivity = "mouse.activity"
    case interactionIdle = "interaction.idle"
    case interactionActive = "interaction.active"
}

struct NoxEvent: Identifiable, Sendable {
    let id: UUID
    let type: NoxEventType
    let timestamp: Date
    let payload: NoxEventPayload

    init(
        id: UUID = UUID(),
        type: NoxEventType,
        timestamp: Date = Date(),
        payload: NoxEventPayload
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.payload = payload
    }
}

enum NoxEventPayload: Sendable {
    case appChanged(AppChangedPayload)
    case windowChanged(WindowChangedPayload)
    case idle(IdlePayload)
    case session(SessionPayload)
    case presence(PresencePayload)
    case permission(PermissionPayload)
    case system(SystemPayload)
    case interaction(InteractionPayload)
}

struct AppChangedPayload: Sendable, Equatable {
    let appName: String
    let bundleId: String
    let windowTitle: String?
    let previousAppName: String?
    let previousBundleId: String?
}

struct WindowChangedPayload: Sendable, Equatable {
    let appName: String
    let bundleId: String
    let windowTitle: String
    let previousWindowTitle: String?
}

struct IdlePayload: Sendable, Equatable {
    let idleSeconds: TimeInterval
}

struct SessionPayload: Sendable, Equatable {
    let sessionId: String
    let primaryApp: String
    let primaryBundleId: String
    let durationMs: Int
    let confidence: Double
    let state: String
}

struct PresencePayload: Sendable, Equatable {
    let previous: String
    let current: String
}

struct PermissionPayload: Sendable, Equatable {
    let mode: String
    let accessibilityGranted: Bool
    let screenRecordingGranted: Bool
}

struct SystemPayload: Sendable, Equatable {
    let message: String
}
