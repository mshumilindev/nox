import Foundation

struct NoxTimelineRecord: Identifiable, Equatable, Sendable {
    let id: String
    let type: String
    let timestamp: Date
    let source: String
    let appName: String?
    let bundleId: String?
    let windowTitle: String?
    let durationMs: Int?
    let metadataJson: String?
    let displayText: String
}
