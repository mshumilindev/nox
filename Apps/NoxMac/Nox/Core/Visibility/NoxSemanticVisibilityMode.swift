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
import NoxShrineCore

enum NoxSemanticVisibilityMode: String, Codable, Sendable, CaseIterable {
    case visibleLocally
    case semanticOnly
    case generalized
    case privateHidden
    case hiddenFromReflections

    var title: String {
        switch self {
        case .visibleLocally: "Visible locally"
        case .semanticOnly: "Semantic-only"
        case .generalized: "Generalized"
        case .privateHidden: "Private"
        case .hiddenFromReflections: "Hidden from reflections"
        }
    }

    var detail: String {
        switch self {
        case .visibleLocally:
            "Stored as calm local memory on this Mac."
        case .semanticOnly:
            "Shape and rhythm only — not detailed content."
        case .generalized:
            "Sensitive continuity is generalized before storage."
        case .privateHidden:
            "Private context — minimal detail retained."
        case .hiddenFromReflections:
            "May inform presence, not reflective summaries."
        }
    }
}

enum NoxSemanticVisibilityPresenter {

    static func mode(for sensitivity: NoxSensitivityLevel) -> NoxSemanticVisibilityMode {
        switch sensitivity {
        case .normal, .personal:
            return .visibleLocally
        case .sensitive:
            return .generalized
        case .privateContext:
            return .privateHidden
        }
    }

    static func line(for sensitivity: NoxSensitivityLevel) -> String? {
        let mode = mode(for: sensitivity)
        switch mode {
        case .generalized:
            return "Generalized private context"
        case .privateHidden:
            return "Private — limited local detail"
        default:
            return nil
        }
    }
}
