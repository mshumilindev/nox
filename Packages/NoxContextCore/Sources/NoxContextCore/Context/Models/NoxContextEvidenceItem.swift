import Foundation
import NoxCore

public enum NoxContextEvidenceSource: String, Codable, Sendable, CaseIterable {
    case system
    case adapter
    case interaction
    case permission
    case sensitivity
    case resolver
}

public enum NoxContextEvidenceKind: String, Codable, Sendable, CaseIterable {
    case foregroundApp
    case windowTitle
    case browserURL
    case browserDomain
    case browserPageTitle
    case documentHint
    case mediaHint
    case fileTransferHint
    case interactionShape
    case capability
    case candidate
    case dominance
    case sensitivity
    case redaction
}

public struct NoxContextEvidenceItem: Equatable, Sendable, Identifiable {
    public let id: String
    public let source: NoxContextEvidenceSource
    public let kind: NoxContextEvidenceKind
    public let value: String
    public let confidence: Double
    public let freshnessSeconds: TimeInterval
    public let sensitivityRisk: NoxSensitivityLevel
    public let explanation: String
    public let adapterId: String?

    public init(
        id: String? = nil,
        source: NoxContextEvidenceSource,
        kind: NoxContextEvidenceKind,
        value: String,
        confidence: Double,
        freshnessSeconds: TimeInterval,
        sensitivityRisk: NoxSensitivityLevel = .normal,
        explanation: String,
        adapterId: String? = nil
    ) {
        self.id = id ?? "\(source.rawValue)-\(kind.rawValue)-\(value.prefix(48))"
        self.source = source
        self.kind = kind
        self.value = value
        self.confidence = confidence
        self.freshnessSeconds = freshnessSeconds
        self.sensitivityRisk = sensitivityRisk
        self.explanation = explanation
        self.adapterId = adapterId
    }
}
