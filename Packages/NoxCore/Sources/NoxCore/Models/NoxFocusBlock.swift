import Foundation

public enum NoxFocusBlockKind: String, Codable, Sendable {
    case focused
    case deepWork
    case fragmented
}

public struct NoxFocusBlock: Identifiable, Equatable, Codable, Sendable {
    public let id: String
    public let startedAt: Date
    public let endedAt: Date
    public let primaryApp: String
    public let primaryBundleId: String
    public let durationMs: Int
    public let switchCount: Int
    public let intensity: Double
    public let continuityScore: Double
    public let kind: NoxFocusBlockKind

    public init(
        id: String,
        startedAt: Date,
        endedAt: Date,
        primaryApp: String,
        primaryBundleId: String,
        durationMs: Int,
        switchCount: Int,
        intensity: Double,
        continuityScore: Double,
        kind: NoxFocusBlockKind
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.primaryApp = primaryApp
        self.primaryBundleId = primaryBundleId
        self.durationMs = durationMs
        self.switchCount = switchCount
        self.intensity = intensity
        self.continuityScore = continuityScore
        self.kind = kind
    }
}
