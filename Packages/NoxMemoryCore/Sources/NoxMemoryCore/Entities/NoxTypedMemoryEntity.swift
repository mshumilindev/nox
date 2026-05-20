import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

public struct NoxTypedMemoryEntity: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let kind: NoxTypedMemoryKind
    public let title: String
    public let summary: String
    public let periodStart: Date?
    public let periodEnd: Date?
    public let confidence: Double
    public let supportingSignals: [NoxExplainableSignal]
    public let metadata: [String: String]
    public let sensitivityLevel: NoxSensitivityLevel
    public let sourceHorizon: NoxMemoryCompressionLevel?
    public let createdAt: Date
    public let updatedAt: Date

    public var isExcludedFromAnalysis: Bool {
        metadata["analysis_category"] == NoxAnalysisCategory.systemInternal.rawValue
    }

    public init(
        id: String,
        kind: NoxTypedMemoryKind,
        title: String,
        summary: String,
        periodStart: Date?,
        periodEnd: Date?,
        confidence: Double,
        supportingSignals: [NoxExplainableSignal],
        metadata: [String: String],
        sensitivityLevel: NoxSensitivityLevel,
        sourceHorizon: NoxMemoryCompressionLevel?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.summary = summary
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.confidence = confidence
        self.supportingSignals = supportingSignals
        self.metadata = metadata
        self.sensitivityLevel = sensitivityLevel
        self.sourceHorizon = sourceHorizon
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
