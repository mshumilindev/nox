import Foundation
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore

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
        case .minimal: "Basic awareness"
        case .appAwareness: "App awareness"
        case .contextAwareness: "Window context"
        case .fullSemantic: "Full local context"
        }
    }

    var scopeLabel: String {
        switch self {
        case .minimal: "Limited detail right now"
        case .appAwareness: "Apps in focus, generalized detail"
        case .contextAwareness: "Window titles when allowed"
        case .fullSemantic: "Rich local context on this Mac"
        }
    }

    var exampleLine: String {
        switch self {
        case .minimal:
            "Nox can stay present with minimal local signals."
        case .appAwareness:
            "Knows which apps are active — not window titles."
        case .contextAwareness:
            "Can read window titles and tie them to sessions."
        case .fullSemantic:
            "Forms local memory and pattern summaries."
        }
    }
}
