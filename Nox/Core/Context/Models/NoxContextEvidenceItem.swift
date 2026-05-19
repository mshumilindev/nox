import Foundation

enum NoxContextEvidenceSource: String, Codable, Sendable, CaseIterable {
    case system
    case adapter
    case interaction
    case permission
    case sensitivity
    case resolver
}

enum NoxContextEvidenceKind: String, Codable, Sendable, CaseIterable {
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

struct NoxContextEvidenceItem: Equatable, Sendable, Identifiable {
    let id: String
    let source: NoxContextEvidenceSource
    let kind: NoxContextEvidenceKind
    let value: String
    let confidence: Double
    let freshnessSeconds: TimeInterval
    let sensitivityRisk: NoxSensitivityLevel
    let explanation: String
    let adapterId: String?

    init(
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
