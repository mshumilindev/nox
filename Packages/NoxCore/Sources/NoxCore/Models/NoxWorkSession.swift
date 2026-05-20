import Foundation

public struct NoxWorkSession: Equatable, Sendable {
    public let id: String

    public init(
        id: String,
        startedAt: Date,
        endedAt: Date? = nil,
        primaryApp: String,
        primaryBundleId: String,
        interruptionCount: Int = 0,
        appSwitchCount: Int = 0,
        confidence: Double = 0,
        state: NoxWorkSessionState = .active
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.primaryApp = primaryApp
        self.primaryBundleId = primaryBundleId
        self.interruptionCount = interruptionCount
        self.appSwitchCount = appSwitchCount
        self.confidence = confidence
        self.state = state
    }
    public var startedAt: Date
    public var endedAt: Date?
    public var primaryApp: String
    public var primaryBundleId: String
    public var interruptionCount: Int
    public var appSwitchCount: Int
    public var confidence: Double
    public var state: NoxWorkSessionState

    public var durationMs: Int {
        let end = endedAt ?? Date()
        return max(0, Int(end.timeIntervalSince(startedAt) * 1000))
    }

    public var summaryLine: String {
        let minutes = max(1, durationMs / 60_000)
        let unit = minutes == 1 ? "minute" : "minutes"
        if endedAt == nil {
            return "\(primaryApp) in focus for \(minutes) \(unit)"
        }
        return "\(primaryApp) was in focus for \(minutes) \(unit)"
    }
}

public enum NoxWorkSessionState: String, Sendable {
    case active
    case ended
}

