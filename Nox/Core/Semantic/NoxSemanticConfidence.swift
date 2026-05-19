import Foundation

enum NoxSemanticConfidence {
    static let surfaceThreshold = 0.45
    static let liveSignalThreshold = 0.62
    static let memorySpanThreshold = 0.38
    static let transientThreshold = 0.32

    /// Internal analytics only — not shown in product UI.
    static func qualifier(for confidence: Double) -> String {
        switch confidence {
        case 0.8...: return "Strong signal:"
        case 0.6..<0.8: return "Likely"
        case 0.45..<0.6: return "Possibly"
        default: return ""
        }
    }

    static func phrase(
        qualifier: String,
        core: String,
        confidence: Double
    ) -> String {
        guard confidence >= surfaceThreshold else { return "" }
        let trimmedQualifier = qualifier.trimmingCharacters(in: .whitespaces)
        if trimmedQualifier.isEmpty { return core }
        if trimmedQualifier.hasSuffix(":") {
            return "\(trimmedQualifier) \(core.lowercased())"
        }
        return "\(trimmedQualifier) \(core.lowercased())"
    }

    static func shouldSurface(_ confidence: Double) -> Bool {
        confidence >= surfaceThreshold
    }
}
