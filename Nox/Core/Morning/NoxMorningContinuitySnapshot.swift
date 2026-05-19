import Foundation

enum NoxMorningTrigger: String, Codable, Sendable {
    case appLaunch
    case newDay
    case longIdleReturn
    case morningWindow
}

struct NoxMorningContinuitySnapshot: Equatable, Sendable {
    let generatedAt: Date
    let trigger: NoxMorningTrigger
    let lines: [String]
}

struct NoxMorningSummary: Equatable, Sendable {
    let snapshot: NoxMorningContinuitySnapshot
    let headline: String
    let supportingLines: [String]

    var isEmpty: Bool { headline.isEmpty && supportingLines.isEmpty }
}
