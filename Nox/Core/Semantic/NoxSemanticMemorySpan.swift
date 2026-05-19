import Foundation

struct NoxSemanticMemorySpan: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let startedAt: Date
    var endedAt: Date?
    let title: String
    let subtitle: String
    let interactionStyle: String
    let semanticState: NoxSemanticState
    let fusionLabel: NoxFusionLabel
    let sensitivityLevel: NoxSensitivityLevel
    let confidence: Double
    let appNames: [String]
    let reasonsJson: String?
    let metadataJson: String?

    init(
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

    var durationMs: Int {
        let end = endedAt ?? Date()
        return max(0, Int(end.timeIntervalSince(startedAt) * 1000))
    }
}
