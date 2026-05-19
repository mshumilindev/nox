import Foundation

enum NoxFocusBlockKind: String, Codable, Sendable {
    case focused
    case deepWork
    case fragmented
}

struct NoxFocusBlock: Identifiable, Equatable, Codable, Sendable {
    let id: String
    let startedAt: Date
    let endedAt: Date
    let primaryApp: String
    let primaryBundleId: String
    let durationMs: Int
    let switchCount: Int
    let intensity: Double
    let continuityScore: Double
    let kind: NoxFocusBlockKind
}
