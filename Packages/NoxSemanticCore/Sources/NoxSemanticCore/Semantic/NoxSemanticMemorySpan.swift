import Foundation
import NoxCore
import NoxContextCore

public struct NoxSemanticMemorySpan: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let startedAt: Date
    public var endedAt: Date?
    public let title: String
    public let subtitle: String
    public let interactionStyle: String
    public let semanticState: NoxSemanticState
    public let fusionLabel: NoxFusionLabel
    public let sensitivityLevel: NoxSensitivityLevel
    public let confidence: Double
    public let appNames: [String]
    public let reasonsJson: String?
    public let metadataJson: String?

    public init(
        id: String,
        startedAt: Date,
        endedAt: Date?,
        title: String,
        subtitle: String,
        interactionStyle: String,
        semanticState: NoxSemanticState,
        fusionLabel: NoxFusionLabel,
        sensitivityLevel: NoxSensitivityLevel,
        confidence: Double,
        appNames: [String],
        reasonsJson: String?,
        metadataJson: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.title = title
        self.subtitle = subtitle
        self.interactionStyle = interactionStyle
        self.semanticState = semanticState
        self.fusionLabel = fusionLabel
        self.sensitivityLevel = sensitivityLevel
        self.confidence = confidence
        self.appNames = appNames
        self.reasonsJson = reasonsJson
        self.metadataJson = metadataJson
    }

    public var durationMs: Int {
        let end = endedAt ?? Date()
        return max(0, Int(end.timeIntervalSince(startedAt) * 1000))
    }
}
