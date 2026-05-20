import Foundation
import NoxCore
import NoxContextCore

/// Calm, human-facing semantic labels — memory, not telemetry.
public enum NoxSemanticLabelCatalog {

    // MARK: - Memory block titles

    public static func memoryTitle(
        inference: NoxSemanticInference,
        appName: String?
    ) -> String {
        if inference.sensitivityLevel != .normal && inference.sensitivityLevel != .personal {
            return NoxSensitiveContextHandler.genericMemoryTitle(sensitivity: inference.sensitivityLevel)
        }

        if let ai = inference.aiWorkflow, ai != .unknown {
            return memoryTitleForAI(ai, inference: inference, appName: appName)
        }

        if inference.fusionLabel == .likelyAIAssistedWork || inference.browserCategory == .aiWorkflow {
            return NoxHumanContextCopy.hasStrongDevelopmentEvidence(inference: inference, appName: appName)
                ? "AI-assisted development"
                : "AI-assisted work"
        }

        switch inference.fusionLabel {
        case .likelyTravelPlanning: return "Travel planning"
        case .likelyShopping: return "Shopping research"
        case .likelyPassiveEntertainment: return "Passive viewing"
        case .likelyFileTransfer: return "File transfer"
        case .likelyGaming: return "Playing"
        case .likelyCreativeWork: return "Creative work"
        case .likelyCommunication: return "Messages"
        case .likelyInteractiveBrowsing: return "Interactive browsing"
        case .likelyResearch: return "Research"
        case .likelyWorkRelated:
            return NoxHumanContextCopy.hasStrongDevelopmentEvidence(inference: inference, appName: appName)
                ? "Development context"
                : "Sustained focus"
        default:
            break
        }

        switch inference.state {
        case .reading: return "Reading"
        case .writing: return "Writing"
        case .passiveConsumption: return "Passive viewing"
        case .fragmentedInteraction:
            return NoxHumanContextCopy.fragmentedLabel(workLike: NoxHumanContextCopy.isWorkLikeContext(inference))
        case .sustainedInteraction: return "Sustained focus"
        case .comparisonActivity: return "Comparison browsing"
        case .reviewing: return "Reviewing"
        case .waiting: return "Short pause"
        case .activeInteraction: return "Browsing"
        case .unknown:
            if let appName, !appName.isEmpty {
                return NoxHumanContextCopy.focusedInApp(appName)
            }
            return "Brief context"
        }
    }

    public static func memorySubtitle(appNames: [String]) -> String {
        let unique = appNames.filter { !$0.isEmpty }.uniqued()
        guard !unique.isEmpty else { return "" }
        if unique.count <= 3 {
            return unique.joined(separator: " · ")
        }
        return unique.prefix(3).joined(separator: " · ") + " · …"
    }

    /// Activity timeline primary line — category label, never "Unknown".
    public static func activitySpanTitle(
        category: NoxActivityCategory,
        appName: String,
        bundleId: String,
        windowTitle: String? = nil
    ) -> String {
        NoxActivityCategory.resolving(
            stored: category,
            appName: appName,
            bundleId: bundleId,
            windowTitle: windowTitle
        ).displayName
    }

    /// Activity timeline: `App · context` — omit duplicate when context resolves to the app name.
    public static func activitySpanSubtitle(appName: String, contextLabel: String?) -> String {
        let app = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !app.isEmpty else { return contextLabel ?? "" }
        guard let context = contextLabel?.trimmingCharacters(in: .whitespacesAndNewlines), !context.isEmpty else {
            return app
        }
        if context.caseInsensitiveCompare(app) == .orderedSame { return app }
        return "\(app) · \(context)"
    }

    public static func memoryDetail(
        inference: NoxSemanticInference?,
        span: NoxSemanticMemorySpan
    ) -> String {
        if span.sensitivityLevel != .normal {
            return "Generalized activity only"
        }

        if let inference {
            let style = interactionDescriptor(inference: inference, span: span)
            let continuity = continuityDescriptor(span: span, inference: inference)
            if continuity.isEmpty { return style }
            if style.isEmpty { return continuity }
            return "\(style) · \(continuity)"
        }

        return productPhrase(fromTechnical: span.interactionStyle)
    }

    public static func mergedMemoryTitle(
        appNames: [String],
        semanticState: NoxSemanticState,
        fusionLabel: NoxFusionLabel
    ) -> String {
        let inference = NoxSemanticInference(
            state: semanticState,
            confidence: 0.7,
            displayPhrase: "",
            reasons: [],
            fusionLabel: fusionLabel,
            fusionConfidence: 0.7,
            fusionPhrase: "",
            sensitivityLevel: .normal,
            browserCategory: .unknown,
            aiWorkflow: fusionLabel == .likelyAIAssistedWork ? .iterativeWorkflow : nil,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )
        return memoryTitle(inference: inference, appName: appNames.first)
    }

    // MARK: - Semantic pulse (sparse, memory-like)

    public static func semanticPulseTitle(from inference: NoxSemanticInference) -> String? {
        guard inference.shouldSurface,
              inference.confidence >= NoxSemanticConfidence.liveSignalThreshold else {
            return nil
        }
        if inference.sensitivityLevel == .privateContext { return "Private context" }
        if inference.sensitivityLevel == .sensitive { return "Sensitive context" }

        if let ai = inference.aiWorkflow, ai != .unknown {
            switch ai {
            case .iterativeWorkflow, .codeOriented:
                return NoxHumanContextCopy.hasStrongDevelopmentEvidence(inference: inference, appName: nil)
                    ? "Development context"
                    : "AI-assisted work"
            case .passiveAIReading: return "Passive viewing"
            case .promptWriting: return "Writing"
            case .researchHeavy: return "Research"
            case .waitingForGeneration: return "Short pause"
            case .casualChat: return "Messages"
            default: break
            }
        }

        switch inference.fusionLabel {
        case .likelyTravelPlanning: return "Travel planning"
        case .likelyShopping: return "Shopping research"
        case .likelyPassiveEntertainment: return "Watching"
        case .likelyFileTransfer: return "File transfer"
        case .likelyGaming: return "Playing"
        case .likelyCreativeWork: return "Creative work"
        case .likelyCommunication: return "Messages"
        case .likelyInteractiveBrowsing: return "Interactive browsing"
        case .likelyResearch: return "Research browsing"
        case .likelyAIAssistedWork:
            return NoxHumanContextCopy.hasStrongDevelopmentEvidence(inference: inference, appName: nil)
                ? "Development context"
                : "AI-assisted work"
        default:
            break
        }

        switch inference.state {
        case .fragmentedInteraction:
            return NoxHumanContextCopy.fragmentedLabel(workLike: NoxHumanContextCopy.isWorkLikeContext(inference))
        case .reading: return "Reading"
        case .writing: return "Writing"
        case .passiveConsumption: return "Watching"
        case .sustainedInteraction: return "Sustained focus"
        case .comparisonActivity: return "Comparison browsing"
        case .waiting: return "Short pause"
        default:
            return nil
        }
    }

    public static func normalizePulseTitle(_ text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("fragmented") {
            return lower.contains("workflow")
                ? NoxHumanContextCopy.fragmentedWorkflowPeriod
                : NoxHumanContextCopy.fragmentedAttentionPeriod
        }
        if lower.contains("development") && lower.contains("workflow") { return "Development context" }
        if lower.contains("development context") { return "Development context" }
        if lower.contains("focused in") { return text }
        if lower.contains("research browsing") || lower.contains("reading") { return "Reading" }
        if lower.contains("writing") { return "Writing" }
        if lower.contains("passive") || lower.contains("viewing") || lower.contains("watching") { return "Watching" }
        if lower.contains("file transfer") { return "File transfer" }
        if lower.contains("game") || lower.contains("playing") { return "Playing" }
        if lower.contains("creative") { return "Creative work" }
        if lower.contains("conversation") || lower.contains("messages") { return "Messages" }
        if lower.contains("interactive browsing") { return "Interactive browsing" }
        if lower.contains("travel") { return "Travel planning" }
        if lower.contains("shopping") { return "Shopping research" }
        if lower.contains("quiet") { return "Quiet period" }
        if lower.contains("short pause") { return "Short pause" }
        if text.hasSuffix(" period") || text.hasSuffix(" session") {
            return text.replacingOccurrences(of: " session", with: "").replacingOccurrences(of: " period", with: "")
        }
        if text.hasSuffix(" resumed") {
            return normalizePulseTitle(String(text.dropLast(" resumed".count)))
        }
        return text
    }

    public static func liveSignalPhrase(from inference: NoxSemanticInference) -> String? {
        semanticPulseTitle(from: inference)
    }

    public static func continuityResumedPhrase(from inference: NoxSemanticInference) -> String? {
        guard let base = semanticPulseTitle(from: inference) else { return nil }
        return "\(base) resumed"
    }

    public static func presenceHint(from inference: NoxSemanticInference) -> String? {
        semanticPulseTitle(from: inference)
    }

    public static func focusBlockTitle(kind: NoxFocusBlockKind) -> String {
        switch kind {
        case .deepWork: return "Deep focus"
        case .focused: return "Sustained focus"
        case .fragmented: return NoxHumanContextCopy.fragmentedAttentionPeriod
        }
    }

    // MARK: - Private

    private static func memoryTitleForAI(
        _ kind: NoxAIWorkflowKind,
        inference: NoxSemanticInference,
        appName: String?
    ) -> String {
        switch kind {
        case .iterativeWorkflow, .codeOriented:
            return NoxHumanContextCopy.hasStrongDevelopmentEvidence(inference: inference, appName: appName)
                ? "AI-assisted development"
                : "AI-assisted work"
        case .passiveAIReading:
            return "Passive viewing"
        case .promptWriting:
            return "Writing"
        case .researchHeavy:
            return "Research"
        case .waitingForGeneration:
            return "Short pause"
        case .casualChat:
            return "Messages"
        case .unknown:
            return NoxHumanContextCopy.hasStrongDevelopmentEvidence(inference: inference, appName: appName)
                ? "AI-assisted development"
                : "AI-assisted work"
        }
    }

    private static func interactionDescriptor(
        inference: NoxSemanticInference,
        span: NoxSemanticMemorySpan
    ) -> String {
        switch inference.state {
        case .reading: return "Reading-focused"
        case .writing: return "Writing-focused"
        case .passiveConsumption: return "Quiet viewing"
        case .fragmentedInteraction: return "Switching between contexts"
        case .comparisonActivity: return "Comparison browsing"
        case .sustainedInteraction: return "Steady continuity"
        default:
            return productPhrase(fromTechnical: span.interactionStyle)
        }
    }

    private static func continuityDescriptor(
        span: NoxSemanticMemorySpan,
        inference: NoxSemanticInference
    ) -> String {
        let minutes = span.durationMs / 60_000
        if inference.state == .fragmentedInteraction {
            return minutes >= 15 ? "Several contexts in motion" : ""
        }
        if minutes >= 45 { return "Low interruption continuity" }
        if minutes >= 20 { return "Moderate continuity" }
        return ""
    }

    private static func productPhrase(fromTechnical phrase: String) -> String {
        let lower = phrase.lowercased()
        if lower.isEmpty { return "" }
        if lower.contains("reading-heavy") { return "Reading-focused" }
        if lower.contains("writing") { return "Writing-focused" }
        if lower.contains("fragmented") { return NoxHumanContextCopy.switchingBetweenContexts }
        if lower.contains("passive") { return "Passive viewing" }
        if lower.contains("file transfer") { return "File transfer" }
        if lower.contains("game") { return "Playing" }
        if lower.contains("creative") { return "Creative work" }
        if lower.contains("interactive browsing") { return "Interactive browsing" }
        if lower.contains("ai tool") || lower.contains("ai-assisted") { return "AI-assisted work" }
        if lower.contains("interaction") || lower.contains("activity") { return "" }
        if lower.contains("likely") || lower.contains("possibly") || lower.contains("strong signal") {
            let cleaned = phrase
                .replacingOccurrences(of: "Strong signal:", with: "")
                .replacingOccurrences(of: "Likely", with: "")
                .replacingOccurrences(of: "Possibly", with: "")
                .trimmingCharacters(in: .whitespaces)
            return cleaned.isEmpty ? "" : cleaned
        }
        return phrase
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
