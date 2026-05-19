import Foundation

enum NoxActivityCategory: String, Codable, CaseIterable, Sendable {
    case productivity
    case development
    case research
    case communication
    case entertainment
    case passive
    case creative
    case system
    /// Nox configuration / internal — never behavioral memory.
    case systemInternal = "system_internal"
    case unknown

    var displayName: String {
        switch self {
        case .productivity: "Productivity"
        case .development: "Development"
        case .research: "Research"
        case .communication: "Communication"
        case .entertainment: "Entertainment"
        case .passive: "Passive"
        case .creative: "Creative"
        case .system: "System"
        case .systemInternal: "System (internal)"
        case .unknown: "Unknown"
        }
    }

    var analysisCategory: NoxAnalysisCategory {
        switch self {
        case .systemInternal: .systemInternal
        default: .behavioral
        }
    }

    var excludedFromAnalysis: Bool {
        !analysisCategory.participatesInBehavioralModel
    }

    var isWorkLike: Bool {
        switch self {
        case .development, .research, .productivity, .creative: true
        case .systemInternal: false
        default: false
        }
    }
}
