import Foundation
import NoxCore
import NoxContextCore

/// Merges nearby semantic spans into coherent memory sessions for display and persistence continuity.
public enum NoxSemanticSpanStitcher {
    private static let maxGapSeconds: TimeInterval = 30 * 60

    public static func stitch(_ spans: [NoxSemanticMemorySpan]) -> [NoxSemanticMemorySpan] {
        let sorted = spans
            .filter { $0.sensitivityLevel == .normal || $0.sensitivityLevel == .personal }
            .sorted { $0.startedAt < $1.startedAt }
        guard !sorted.isEmpty else { return spans }

        var merged: [NoxSemanticMemorySpan] = []
        var current = sorted[0]

        for span in sorted.dropFirst() {
            if shouldMerge(current, span) {
                current = merge(current, span)
            } else {
                merged.append(current)
                current = span
            }
        }
        merged.append(current)

        let sensitive = spans.filter { $0.sensitivityLevel != .normal && $0.sensitivityLevel != .personal }
        return (merged + sensitive).sorted { $0.startedAt > $1.startedAt }
    }

    static func stitchKey(for span: NoxSemanticMemorySpan) -> String {
        ecosystemKey(
            fusionLabel: span.fusionLabel,
            semanticState: span.semanticState,
            appNames: span.appNames,
            title: span.title
        )
    }

    public static func shouldContinueOpenSpan(
        _ open: NoxSemanticMemorySpan,
        inference: NoxSemanticInference,
        appName: String?,
        at date: Date,
        dominantContext: NoxDominantContextType? = nil
    ) -> Bool {
        let gap = date.timeIntervalSince(open.endedAt ?? open.startedAt)
        guard gap <= maxGapSeconds else { return false }

        if let dominantContext, conflictsWithOpenSpan(open, dominant: dominantContext) {
            return false
        }

        let proposedTitle = NoxSemanticLabelCatalog.memoryTitle(inference: inference, appName: appName)
        if open.title == proposedTitle { return true }

        let openKey = stitchKey(for: open)
        let proposedKey = ecosystemKey(
            fusionLabel: inference.fusionLabel,
            semanticState: inference.state,
            appNames: open.appNames + [appName].compactMap { $0 },
            title: proposedTitle
        )
        if openKey == proposedKey { return true }

        return compatibleWorkflow(open: open, inference: inference, appName: appName)
    }

    // MARK: - Private

    private static func ecosystemKey(
        fusionLabel: NoxFusionLabel,
        semanticState: NoxSemanticState,
        appNames: [String],
        title: String
    ) -> String {
        if fusionLabel == .likelyAIAssistedWork || containsAIApp(appNames) {
            return containsDevApp(appNames) ? "ai-dev" : "ai-research"
        }
        switch fusionLabel {
        case .likelyResearch: return "research"
        case .likelyTravelPlanning: return "travel"
        case .likelyShopping: return "shopping"
        case .likelyPassiveEntertainment: return "passive"
        case .likelyFileTransfer: return "file-transfer"
        case .likelyGaming: return "gaming"
        case .likelyCreativeWork: return "creative"
        case .likelyCommunication: return "communication"
        case .likelyInteractiveBrowsing: return "interactive"
        case .likelyWorkRelated: return containsDevApp(appNames) ? "dev-work" : "work"
        default:
            break
        }
        switch semanticState {
        case .fragmentedInteraction: return "fragmented"
        case .reading: return "research"
        case .writing: return "writing"
        case .passiveConsumption: return "passive"
        default:
            return title.lowercased()
        }
    }

    private static func shouldMerge(_ a: NoxSemanticMemorySpan, _ b: NoxSemanticMemorySpan) -> Bool {
        let gap = b.startedAt.timeIntervalSince(a.endedAt ?? a.startedAt)
        guard gap <= maxGapSeconds else { return false }
        if stitchKey(for: a) == stitchKey(for: b) { return true }
        if compatibleEcosystem(a, b) { return true }
        return a.title == b.title
    }

    private static func merge(_ a: NoxSemanticMemorySpan, _ b: NoxSemanticMemorySpan) -> NoxSemanticMemorySpan {
        let apps = uniqued(a.appNames + b.appNames)
        let end = b.endedAt ?? b.startedAt
        let fusion = preferFusion(a.fusionLabel, b.fusionLabel)
        let state = preferState(a.semanticState, b.semanticState)
        let title = NoxSemanticLabelCatalog.mergedMemoryTitle(
            appNames: apps,
            semanticState: state,
            fusionLabel: fusion
        )
        return NoxSemanticMemorySpan(
            id: a.id,
            startedAt: a.startedAt,
            endedAt: end,
            title: title,
            subtitle: NoxSemanticLabelCatalog.memorySubtitle(appNames: apps),
            interactionStyle: a.interactionStyle.isEmpty ? b.interactionStyle : a.interactionStyle,
            semanticState: state,
            fusionLabel: fusion,
            sensitivityLevel: a.sensitivityLevel,
            confidence: max(a.confidence, b.confidence),
            appNames: apps,
            reasonsJson: a.reasonsJson ?? b.reasonsJson
        )
    }

    private static func compatibleEcosystem(_ a: NoxSemanticMemorySpan, _ b: NoxSemanticMemorySpan) -> Bool {
        let devA = containsDevApp(a.appNames)
        let devB = containsDevApp(b.appNames)
        let aiA = containsAIApp(a.appNames) || a.fusionLabel == .likelyAIAssistedWork
        let aiB = containsAIApp(b.appNames) || b.fusionLabel == .likelyAIAssistedWork
        if devA && devB && (aiA || aiB) { return true }

        let researchA = a.fusionLabel == .likelyResearch || a.semanticState == .reading
        let researchB = b.fusionLabel == .likelyResearch || b.semanticState == .reading
        if researchA && researchB { return true }

        let travelA = a.fusionLabel == .likelyTravelPlanning
        let travelB = b.fusionLabel == .likelyTravelPlanning
        if travelA && travelB { return true }

        return false
    }

    private static func conflictsWithOpenSpan(
        _ open: NoxSemanticMemorySpan,
        dominant: NoxDominantContextType
    ) -> Bool {
        switch dominant {
        case .watching, .listening:
            return open.semanticState == .writing || open.semanticState == .fragmentedInteraction
        case .writing, .development:
            return open.semanticState == .passiveConsumption
        default:
            return false
        }
    }

    private static func compatibleWorkflow(
        open: NoxSemanticMemorySpan,
        inference: NoxSemanticInference,
        appName: String?
    ) -> Bool {
        var apps = open.appNames
        if let appName { apps.append(appName) }
        let dev = containsDevApp(apps)
        let ai = containsAIApp(apps)
            || inference.fusionLabel == .likelyAIAssistedWork
            || inference.browserCategory == .aiWorkflow
        if dev && ai { return true }
        return false
    }

    private static func containsDevApp(_ names: [String]) -> Bool {
        let markers = ["Xcode", "Cursor", "Terminal", "iTerm", "GitHub", "VS Code"]
        return names.contains { name in markers.contains { name.localizedCaseInsensitiveContains($0) } }
    }

    private static func containsAIApp(_ names: [String]) -> Bool {
        let markers = ["ChatGPT", "Claude", "Copilot", "Perplexity"]
        return names.contains { name in markers.contains { name.localizedCaseInsensitiveContains($0) } }
    }

    private static func preferFusion(_ a: NoxFusionLabel, _ b: NoxFusionLabel) -> NoxFusionLabel {
        if a == .likelyAIAssistedWork || b == .likelyAIAssistedWork { return .likelyAIAssistedWork }
        if a == .likelyFileTransfer || b == .likelyFileTransfer { return .likelyFileTransfer }
        if a == .likelyGaming || b == .likelyGaming { return .likelyGaming }
        if a == .likelyInteractiveBrowsing || b == .likelyInteractiveBrowsing { return .likelyInteractiveBrowsing }
        if a != .unknown { return a }
        return b
    }

    private static func preferState(_ a: NoxSemanticState, _ b: NoxSemanticState) -> NoxSemanticState {
        if a == .writing || b == .writing { return .writing }
        if a == .reading || b == .reading { return .reading }
        if a == .fragmentedInteraction || b == .fragmentedInteraction { return .fragmentedInteraction }
        return a
    }

    private static func uniqued(_ items: [String]) -> [String] {
        var seen = Set<String>()
        return items.filter { seen.insert($0).inserted }
    }
}
