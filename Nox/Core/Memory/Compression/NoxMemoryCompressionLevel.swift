import Foundation

/// Adaptive memory horizons. Each level extracts different meaning — not repeated summaries.
enum NoxMemoryCompressionLevel: String, Codable, Sendable, CaseIterable {
    case hourly
    case daily
    case weekly
    case monthly
    case quarterly
    case yearly
    case era

    var title: String {
        switch self {
        case .hourly: "Hourly"
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .quarterly: "Quarterly"
        case .yearly: "Yearly"
        case .era: "Era"
        }
    }

    /// What this horizon answers — guides deterministic compression.
    var semanticIntent: String {
        switch self {
        case .hourly: "Short continuity windows"
        case .daily: "What happened?"
        case .weekly: "What repeated?"
        case .monthly: "What became a pattern?"
        case .quarterly: "What became a direction?"
        case .yearly: "What changed?"
        case .era: "What kind of period was this?"
        }
    }

    var parentLevel: NoxMemoryCompressionLevel? {
        switch self {
        case .hourly: .daily
        case .daily: .weekly
        case .weekly: .monthly
        case .monthly: .quarterly
        case .quarterly: .yearly
        case .yearly: .era
        case .era: nil
        }
    }

    var childLevel: NoxMemoryCompressionLevel? {
        switch self {
        case .hourly: nil
        case .daily: .hourly
        case .weekly: .daily
        case .monthly: .weekly
        case .quarterly: .monthly
        case .yearly: .quarterly
        case .era: .yearly
        }
    }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        if raw == "decade" {
            self = .era
        } else {
            self = NoxMemoryCompressionLevel(rawValue: raw) ?? .daily
        }
    }
}
