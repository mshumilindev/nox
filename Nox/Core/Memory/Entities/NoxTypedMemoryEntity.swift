import Foundation

struct NoxTypedMemoryEntity: Identifiable, Equatable, Sendable, Codable {
    let id: String
    let kind: NoxTypedMemoryKind
    let title: String
    let summary: String
    let periodStart: Date?
    let periodEnd: Date?
    let confidence: Double
    let supportingSignals: [NoxExplainableSignal]
    let metadata: [String: String]
    let sensitivityLevel: NoxSensitivityLevel
    let sourceHorizon: NoxMemoryCompressionLevel?
    let createdAt: Date
    let updatedAt: Date

    var isExcludedFromAnalysis: Bool {
        metadata["analysis_category"] == NoxAnalysisCategory.systemInternal.rawValue
    }
}
