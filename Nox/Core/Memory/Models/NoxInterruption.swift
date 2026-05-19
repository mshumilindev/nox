import Foundation

struct NoxInterruption: Identifiable, Equatable, Codable, Sendable {
    let id: String
    let timestamp: Date
    let fromApp: String
    let fromBundleId: String
    let toApp: String
    let toBundleId: String
    let durationMs: Int
    let returnedBack: Bool
}
