import Foundation

/// How settled a semantic observation is — never binary empty vs full.
enum NoxMemoryMaturity: String, Codable, Sendable, CaseIterable {
    case transient
    case emerging
    case stable
    case durable

    var sortOrder: Int {
        switch self {
        case .transient: return 0
        case .emerging: return 1
        case .stable: return 2
        case .durable: return 3
        }
    }
}

struct NoxEmergingMemoryObservation: Identifiable, Equatable, Sendable {
    let id: String
    let maturity: NoxMemoryMaturity
    let title: String
    let detail: String?
    let confidence: Double
}
