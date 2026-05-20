import Foundation

/// How settled a semantic observation is — never binary empty vs full.
public enum NoxMemoryMaturity: String, Codable, Sendable, CaseIterable {
    case transient
    case emerging
    case stable
    case durable

    public var sortOrder: Int {
        switch self {
        case .transient: return 0
        case .emerging: return 1
        case .stable: return 2
        case .durable: return 3
        }
    }
}

public struct NoxEmergingMemoryObservation: Identifiable, Equatable, Sendable {
    public let id: String
    public let maturity: NoxMemoryMaturity
    public let title: String
    public let detail: String?
    public let confidence: Double

    public init(id: String, maturity: NoxMemoryMaturity, title: String, detail: String?, confidence: Double) {
        self.id = id
        self.maturity = maturity
        self.title = title
        self.detail = detail
        self.confidence = confidence
    }
}
