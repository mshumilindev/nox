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
    /// Legacy stored value — reclassified on read; never shown in UI.
    case unknown
    /// Residual bucket when heuristics are thin — still human-readable.
    case general

    init?(rawValue: String) {
        switch rawValue {
        case "productivity": self = .productivity
        case "development": self = .development
        case "research": self = .research
        case "communication": self = .communication
        case "entertainment": self = .entertainment
        case "passive": self = .passive
        case "creative": self = .creative
        case "system": self = .system
        case "system_internal": self = .systemInternal
        case "unknown": self = .unknown
        case "general": self = .general
        default: return nil
        }
    }

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
        case .general: "Active use"
        case .unknown: "Active use"
        }
    }

    var symbolName: String {
        let candidate: String
        switch self {
        case .development: candidate = "hammer.fill"
        case .research: candidate = "book.fill"
        case .communication: candidate = "bubble.left.and.bubble.right.fill"
        case .productivity: candidate = "doc.text.fill"
        case .creative: candidate = "paintbrush.fill"
        case .passive: candidate = "play.circle.fill"
        case .entertainment: candidate = "gamecontroller.fill"
        case .system, .systemInternal: candidate = "gearshape.fill"
        case .general, .unknown: candidate = "app.fill"
        }
        return NoxSFSymbol.validated(candidate, fallback: "app.fill")
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

    var needsStoredReclassification: Bool {
        self == .unknown
    }

    /// Re-run app classification for legacy `unknown` rows and thin `general` spans.
    static func resolving(
        stored: NoxActivityCategory,
        appName: String,
        bundleId: String,
        windowTitle: String? = nil
    ) -> NoxActivityCategory {
        guard stored.needsStoredReclassification || stored == .general else { return stored }
        let classified = NoxAppClassifier().classify(
            bundleId: bundleId,
            appName: appName,
            windowTitle: windowTitle
        )
        if classified.isBehaviorallyMeaningful {
            return classified
        }
        return stored == .unknown ? .general : stored
    }

    var isBehaviorallyMeaningful: Bool {
        switch self {
        case .unknown, .general, .systemInternal: false
        default: true
        }
    }
}
