import Foundation
import NoxSemanticCore
import NoxMemoryCore
import NoxContextCore
import NoxCore

public enum NoxMorningTrigger: String, Codable, Sendable {
    case appLaunch
    case newDay
    case longIdleReturn
    case morningWindow
}

public struct NoxMorningContinuitySnapshot: Equatable, Sendable {
    public let generatedAt: Date
    public let trigger: NoxMorningTrigger
    public let lines: [String]
}

public struct NoxMorningSummary: Equatable, Sendable {
    public let snapshot: NoxMorningContinuitySnapshot
    public let headline: String
    public let supportingLines: [String]

    public var isEmpty: Bool { headline.isEmpty && supportingLines.isEmpty }
}
