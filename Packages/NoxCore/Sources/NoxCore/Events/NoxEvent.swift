import Foundation

public nonisolated enum NoxEventType: String, Codable, Sendable {
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

public nonisolated struct NoxEvent: Identifiable, Sendable {
    public let id: UUID
    public let type: NoxEventType
    public let timestamp: Date
    public let payload: NoxEventPayload

    public init(
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

public nonisolated enum NoxEventPayload: Sendable {
    case appChanged(AppChangedPayload)
    case windowChanged(WindowChangedPayload)
    case idle(IdlePayload)
    case session(SessionPayload)
    case presence(PresencePayload)
    case permission(PermissionPayload)
    case system(SystemPayload)
    case interaction(InteractionPayload)
}

public struct AppChangedPayload: Sendable, Equatable {
    public let appName: String
    public let bundleId: String
    public let windowTitle: String?
    public let previousAppName: String?
    public let previousBundleId: String?

    public init(
        appName: String,
        bundleId: String,
        windowTitle: String?,
        previousAppName: String?,
        previousBundleId: String?
    ) {
        self.appName = appName
        self.bundleId = bundleId
        self.windowTitle = windowTitle
        self.previousAppName = previousAppName
        self.previousBundleId = previousBundleId
    }
}

public struct WindowChangedPayload: Sendable, Equatable {
    public let appName: String
    public let bundleId: String
    public let windowTitle: String
    public let previousWindowTitle: String?

    public init(
        appName: String,
        bundleId: String,
        windowTitle: String,
        previousWindowTitle: String?
    ) {
        self.appName = appName
        self.bundleId = bundleId
        self.windowTitle = windowTitle
        self.previousWindowTitle = previousWindowTitle
    }
}

public struct IdlePayload: Sendable, Equatable {
    public let idleSeconds: TimeInterval

    public init(idleSeconds: TimeInterval) {
        self.idleSeconds = idleSeconds
    }
}

public struct SessionPayload: Sendable, Equatable {
    public let sessionId: String
    public let primaryApp: String
    public let primaryBundleId: String
    public let durationMs: Int
    public let confidence: Double
    public let state: String

    public init(
        sessionId: String,
        primaryApp: String,
        primaryBundleId: String,
        durationMs: Int,
        confidence: Double,
        state: String
    ) {
        self.sessionId = sessionId
        self.primaryApp = primaryApp
        self.primaryBundleId = primaryBundleId
        self.durationMs = durationMs
        self.confidence = confidence
        self.state = state
    }
}

public struct PresencePayload: Sendable, Equatable {
    public let previous: String
    public let current: String

    public init(previous: String, current: String) {
        self.previous = previous
        self.current = current
    }
}

public struct PermissionPayload: Sendable, Equatable {
    public let mode: String
    public let accessibilityGranted: Bool
    public let screenRecordingGranted: Bool

    public init(mode: String, accessibilityGranted: Bool, screenRecordingGranted: Bool) {
        self.mode = mode
        self.accessibilityGranted = accessibilityGranted
        self.screenRecordingGranted = screenRecordingGranted
    }
}

public struct SystemPayload: Sendable, Equatable {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}
