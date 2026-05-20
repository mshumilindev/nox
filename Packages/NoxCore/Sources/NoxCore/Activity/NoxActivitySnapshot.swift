import Foundation

public struct NoxActivitySnapshot: Equatable, Sendable {
    public let appName: String
    public let bundleId: String
    public let windowTitle: String?
    /// Browser address bar / document URL from Accessibility when available.
    public let documentURL: String?
    public let processId: Int32?
    public let idleSeconds: TimeInterval
    public let isUserIdle: Bool
    public let capturedAt: Date

    public init(
        appName: String,
        bundleId: String,
        windowTitle: String?,
        documentURL: String?,
        processId: Int32?,
        idleSeconds: TimeInterval,
        isUserIdle: Bool,
        capturedAt: Date
    ) {
        self.appName = appName
        self.bundleId = bundleId
        self.windowTitle = windowTitle
        self.documentURL = documentURL
        self.processId = processId
        self.idleSeconds = idleSeconds
        self.isUserIdle = isUserIdle
        self.capturedAt = capturedAt
    }

    public static let idleThresholdSeconds: TimeInterval = 120
    public static let restingThresholdSeconds: TimeInterval = 600

    public var isIdle: Bool {
        idleSeconds >= Self.idleThresholdSeconds
    }

    public var isResting: Bool {
        idleSeconds >= Self.restingThresholdSeconds
    }

    /// Fields that drive context/semantic/memory pipelines (excludes `capturedAt`).
    public func hasSameObservationSurface(as other: NoxActivitySnapshot) -> Bool {
        bundleId == other.bundleId
            && appName == other.appName
            && windowTitle == other.windowTitle
            && documentURL == other.documentURL
            && isUserIdle == other.isUserIdle
            && idlePresenceBucket == other.idlePresenceBucket
    }

    /// Coarse idle bucket for presence updates without 1 Hz semantic reloads.
    public var idlePresenceBucket: Int {
        if isUserIdle { return -1 }
        switch idleSeconds {
        case ..<30: return 0
        case ..<120: return 1
        default: return 2
        }
    }
}
