import Foundation

public struct NoxFocusAnalysis: Equatable, Sendable {
    public let kind: NoxFocusBlockKind?
    public let uninterruptedMs: Int
    public let switchCount: Int
    public let continuityScore: Double

    public init(
        kind: NoxFocusBlockKind?,
        uninterruptedMs: Int,
        switchCount: Int,
        continuityScore: Double
    ) {
        self.kind = kind
        self.uninterruptedMs = uninterruptedMs
        self.switchCount = switchCount
        self.continuityScore = continuityScore
    }
}
