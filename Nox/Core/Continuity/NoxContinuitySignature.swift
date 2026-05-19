import Foundation

/// Coarse workflow shape — no raw sensitive content.
nonisolated struct NoxContinuitySignature: Equatable, Sendable, Codable {
    let ecosystemKey: String
    let semanticType: NoxContinuitySemanticType
    let appTokens: [String]
    let semanticState: NoxSemanticState
    let fusionLabel: NoxFusionLabel
    let interactionProfile: String
    let densityProfile: String

    static func from(
        inference: NoxSemanticInference,
        appNames: [String],
        appName: String?
    ) -> NoxContinuitySignature {
        var apps = appNames
        if let appName, !apps.contains(appName) { apps.append(appName) }
        let type = NoxContinuitySemanticTypeResolver.resolve(inference: inference, appNames: apps)
        return NoxContinuitySignature(
            ecosystemKey: ecosystemKey(for: type, apps: apps),
            semanticType: type,
            appTokens: normalizedApps(apps),
            semanticState: inference.state,
            fusionLabel: inference.fusionLabel,
            interactionProfile: interactionProfile(for: inference),
            densityProfile: densityProfile(for: inference)
        )
    }

    private static func normalizedApps(_ apps: [String]) -> [String] {
        Array(Set(apps.map { $0.lowercased() }.filter { !$0.isEmpty })).sorted()
    }

    private static func ecosystemKey(for type: NoxContinuitySemanticType, apps: [String]) -> String {
        switch type {
        case .aiDevelopment: return "ai-dev"
        case .research: return "research"
        case .travelPlanning: return "travel"
        case .writing: return "writing"
        case .development: return "dev"
        case .fragmentedWorkflow: return "fragmented"
        case .passiveViewing: return "passive"
        case .privateContext: return "private"
        case .sensitiveContext: return "sensitive"
        case .general:
            return "general-\(primaryAppToken(from: apps) ?? "mixed")"
        }
    }

    private static func primaryAppToken(from apps: [String]) -> String? {
        normalizedApps(apps).first.map { app in
            app
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: ".", with: "-")
        }
    }

    private static func interactionProfile(for inference: NoxSemanticInference) -> String {
        switch inference.state {
        case .reading: return "reading-heavy"
        case .writing: return "writing-heavy"
        case .passiveConsumption: return "passive"
        case .fragmentedInteraction: return "fragmented"
        case .sustainedInteraction: return "sustained"
        default: return "mixed"
        }
    }

    private static func densityProfile(for inference: NoxSemanticInference) -> String {
        inference.confidence >= 0.75 ? "dense" : "moderate"
    }
}

nonisolated enum NoxContinuitySemanticTypeResolver {
    static func resolve(
        inference: NoxSemanticInference,
        appNames: [String]
    ) -> NoxContinuitySemanticType {
        if inference.sensitivityLevel == .privateContext { return .privateContext }
        if inference.sensitivityLevel == .sensitive { return .sensitiveContext }

        if inference.aiWorkflow != nil || inference.fusionLabel == .likelyAIAssistedWork {
            return containsDevApp(appNames) ? .aiDevelopment : .research
        }
        switch inference.fusionLabel {
        case .likelyTravelPlanning: return .travelPlanning
        case .likelyResearch: return .research
        case .likelyPassiveEntertainment: return .passiveViewing
        case .likelyWorkRelated: return containsDevApp(appNames) ? .development : .general
        case .likelyFileTransfer, .likelyGaming, .likelyCreativeWork, .likelyCommunication,
                .likelyInteractiveBrowsing:
            return .general
        default: break
        }
        switch inference.state {
        case .fragmentedInteraction: return .fragmentedWorkflow
        case .reading: return .research
        case .writing: return .writing
        case .passiveConsumption: return .passiveViewing
        default: return .general
        }
    }

    private static func containsDevApp(_ names: [String]) -> Bool {
        let markers = [
            "cursor", "xcode", "terminal", "github", "visual studio code", "vscode",
            "jetbrains", "intellij", "webstorm", "pycharm", "rider", "clion",
            "warp", "iterm", "wezterm", "alacritty", "docker", "sublime", "bbedit"
        ]
        return names.contains { name in markers.contains { name.lowercased().contains($0) } }
    }
}
