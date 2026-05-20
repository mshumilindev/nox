import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

public nonisolated struct NoxActivitySpan: Identifiable, Equatable, Codable, Sendable {
    public let id: String
    public var startedAt: Date
    public var endedAt: Date?
    public let appName: String
    public let bundleId: String
    public let windowTitle: String?
    public let contextLabel: String?
    public let category: NoxActivityCategory
    public var interruptions: Int
    public var focusScore: Double
    public let metadataJson: String?

    public init(
        id: String,
        startedAt: Date,
        endedAt: Date? = nil,
        appName: String,
        bundleId: String,
        windowTitle: String? = nil,
        contextLabel: String? = nil,
        category: NoxActivityCategory,
        interruptions: Int = 0,
        focusScore: Double = 0,
        metadataJson: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.appName = appName
        self.bundleId = bundleId
        self.windowTitle = windowTitle
        self.contextLabel = contextLabel
        self.category = category
        self.interruptions = interruptions
        self.focusScore = focusScore
        self.metadataJson = metadataJson
    }

    public var durationMs: Int {
        let end = endedAt ?? Date()
        return max(0, Int(end.timeIntervalSince(startedAt) * 1000))
    }
}
