import Foundation

nonisolated struct NoxActivitySpan: Identifiable, Equatable, Codable, Sendable {
    let id: String
    var startedAt: Date
    var endedAt: Date?
    let appName: String
    let bundleId: String
    let windowTitle: String?
    let contextLabel: String?
    let category: NoxActivityCategory
    var interruptions: Int
    var focusScore: Double
    let metadataJson: String?

    var durationMs: Int {
        let end = endedAt ?? Date()
        return max(0, Int(end.timeIntervalSince(startedAt) * 1000))
    }
}
