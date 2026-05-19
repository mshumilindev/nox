import Foundation

enum NoxSafeDisplayLabelGenerator {
    static func make(
        dominant: NoxContextCandidate?,
        sensitivity: NoxSensitivityLevel,
        sanitizedTitle: String?,
        appName: String
    ) -> NoxSafeContextOutput {
        if sensitivity == .privateContext {
            return output(
                label: "Private context",
                subtitle: nil,
                type: .privateContext,
                secondary: [],
                redacted: true,
                reason: "Private sensitivity gate"
            )
        }
        if sensitivity == .sensitive {
            return output(
                label: "Sensitive context",
                subtitle: nil,
                type: .sensitiveContext,
                secondary: [],
                redacted: true,
                reason: "Sensitive content redacted"
            )
        }

        guard let dominant else {
            return output(
                label: "Unknown app context",
                subtitle: appName,
                type: .insufficient,
                secondary: [],
                redacted: false,
                reason: nil
            )
        }

        let base = baseLabel(for: dominant.contextType, appName: appName)
        var subtitle: String?
        var redacted = false
        var reason: String?

        if sensitivity == .personal {
            return output(
                label: "Personal context",
                subtitle: nil,
                type: dominant.contextType,
                secondary: [],
                redacted: true,
                reason: "Personal context generalized"
            )
        } else if let title = safeTitleFragment(from: sanitizedTitle), shouldAttachTitle(for: dominant.contextType) {
            subtitle = title
        }

        let secondary = [dominant.contextType].filter { _ in false }

        return output(
            label: base,
            subtitle: subtitle,
            type: dominant.contextType,
            secondary: secondary,
            redacted: redacted,
            reason: reason
        )
    }

    private static func baseLabel(for type: NoxDominantContextType, appName: String) -> String {
        switch type {
        case .reading: return "Reading"
        case .writing: return "Writing"
        case .watching: return "Watching"
        case .listening: return "Listening"
        case .development:
            return NoxHumanContextCopy.editorFocusLabel(appName: appName) ?? "Development context"
        case .communication: return "Messages"
        case .creativeWork: return "Creative work"
        case .gamingInteractive: return "Playing"
        case .fileTransfer: return "File transfer"
        case .shoppingComparison: return "Shopping research"
        case .travelPlanning: return "Travel planning"
        case .research: return "Research"
        case .privateContext, .sensitiveContext: return "Private context"
        case .unknown: return "Mixed context"
        case .insufficient: return "Context settling"
        }
    }

    private static func shouldAttachTitle(for type: NoxDominantContextType) -> Bool {
        switch type {
        case .reading, .watching, .listening, .writing, .development, .creativeWork, .research:
            return true
        default:
            return false
        }
    }

    private static func safeTitleFragment(from title: String?) -> String? {
        guard let title else { return nil }
        let primary = NoxTitleTokenAnalyzer.primarySegment(from: title) ?? title
        let trimmed = primary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3, trimmed.count <= 48 else { return nil }
        if trimmed.lowercased() == trimmed.uppercased() && trimmed.count > 20 { return nil }
        return trimmed
    }

    private static func output(
        label: String,
        subtitle: String?,
        type: NoxDominantContextType,
        secondary: [NoxDominantContextType],
        redacted: Bool,
        reason: String?
    ) -> NoxSafeContextOutput {
        NoxSafeContextOutput(
            displayLabel: label,
            subtitle: subtitle,
            dominantContextType: type,
            secondaryContextTypes: secondary,
            detailsRedacted: redacted,
            redactionReason: reason
        )
    }
}
