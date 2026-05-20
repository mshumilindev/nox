import Foundation

/// Human-facing awareness ladder — distinct from internal permission tiers.
enum NoxAwarenessLevel: Int, CaseIterable, Codable, Sendable, Comparable {
    case minimal = 0
    case appAwareness = 1
    case contextAwareness = 2
    case fullSemantic = 3

    static func < (lhs: NoxAwarenessLevel, rhs: NoxAwarenessLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .minimal: "Minimal awareness"
        case .appAwareness: "App-level awareness"
        case .contextAwareness: "Context awareness"
        case .fullSemantic: "Full semantic awareness"
        }
    }

    var scopeLabel: String {
        switch self {
        case .minimal: "Limited recent activity available"
        case .appAwareness: "Apps in focus, generalized detail"
        case .contextAwareness: "More detailed window context available"
        case .fullSemantic: "Rich local activity context"
        }
    }

    var exampleLine: String {
        switch self {
        case .minimal:
            "Nox can stay present with minimal local signals."
        case .appAwareness:
            "Knows which apps are active — not window titles."
        case .contextAwareness:
            "Reads window titles and interaction context locally."
        case .fullSemantic:
            "Forms local memory, recurring threads, and reflections."
        }
    }
}
