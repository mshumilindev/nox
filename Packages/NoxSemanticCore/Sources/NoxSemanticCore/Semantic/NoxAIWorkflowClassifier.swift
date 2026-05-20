import Foundation
import NoxCore
import NoxContextCore

public struct NoxAIWorkflowAssessment: Equatable, Sendable {
    public let kind: NoxAIWorkflowKind
    public let confidence: Double
    public let phrase: String
    public let reasons: [NoxSemanticReason]
}

public struct NoxAIWorkflowClassifier {
    public init() {}
    private static let aiBundles: Set<String> = [
        "com.openai.chat",
        "com.todesktop.230313mzl4w4u92"
    ]

    private static let aiHosts: Set<String> = [
        "chatgpt.com", "chat.openai.com", "claude.ai", "cursor.com", "cursor.sh"
    ]

    public func assess(context: NoxSemanticContext) -> NoxAIWorkflowAssessment? {
        guard isAIContext(context) else { return nil }

        var reasons: [NoxSemanticReason] = []
        var scoreByKind: [NoxAIWorkflowKind: Double] = [:]

        reasons.append(NoxSemanticReason(signal: "ai_tool", detail: "AI tool active"))

        let metrics = context.metrics
        let devNearby = hasDevNearby(context)

        if metrics.isWritingHeavy {
            scoreByKind[.promptWriting, default: 0] += 0.35
            reasons.append(NoxSemanticReason(signal: "typing", detail: "sustained typing bursts"))
        }
        if metrics.isReadingHeavy {
            scoreByKind[.passiveAIReading, default: 0] += 0.35
            reasons.append(NoxSemanticReason(signal: "scroll", detail: "reading-heavy scroll pattern"))
        }
        if metrics.isInteractionActive == false && metrics.interactionIdleSeconds > 20 {
            scoreByKind[.waitingForGeneration, default: 0] += 0.3
            reasons.append(NoxSemanticReason(signal: "pause", detail: "low interaction after typing"))
        }
        if devNearby && metrics.isWritingHeavy {
            scoreByKind[.iterativeWorkflow, default: 0] += 0.4
            scoreByKind[.codeOriented, default: 0] += 0.25
            reasons.append(NoxSemanticReason(signal: "nearby_apps", detail: "dev tools nearby"))
        }
        if !devNearby && metrics.typingDensity < 1 && context.hourOfDay >= 21 {
            scoreByKind[.casualChat, default: 0] += 0.25
        }
        if context.browserCategory == .research || context.browserCategory == .reference {
            scoreByKind[.researchHeavy, default: 0] += 0.2
        }

        guard let best = scoreByKind.max(by: { $0.value < $1.value }) else {
            return NoxAIWorkflowAssessment(
                kind: .unknown,
                confidence: 0.35,
                phrase: fallbackPhrase(context: context),
                reasons: reasons
            )
        }

        let confidence = min(0.92, best.value + 0.35)
        let phrase = phrase(for: best.key, confidence: confidence)
        return NoxAIWorkflowAssessment(
            kind: best.key,
            confidence: confidence,
            phrase: phrase,
            reasons: reasons
        )
    }

    private func isAIContext(_ context: NoxSemanticContext) -> Bool {
        if let bundleId = context.bundleId, Self.aiBundles.contains(bundleId) { return true }
        if let domain = context.domain?.lowercased() {
            return Self.aiHosts.contains(where: { domain.contains($0) })
        }
        if context.browserCategory == .aiWorkflow { return true }
        if context.appName?.localizedCaseInsensitiveContains("ChatGPT") == true { return true }
        if context.appName?.localizedCaseInsensitiveContains("Claude") == true { return true }
        return false
    }

    private func hasDevNearby(_ context: NoxSemanticContext) -> Bool {
        let dev = [
            "com.apple.dt.Xcode",
            "com.todesktop.230313mzl4w4u92",
            "com.apple.Terminal",
            "com.googlecode.iterm2"
        ]
        if let bundleId = context.bundleId, dev.contains(bundleId) { return true }
        return context.nearbyBundleIds.contains(where: { dev.contains($0) })
    }

    private func phrase(for kind: NoxAIWorkflowKind, confidence: Double) -> String {
        _ = confidence
        switch kind {
        case .passiveAIReading: return "Passive AI reading"
        case .promptWriting: return "Prompt-writing session"
        case .iterativeWorkflow: return "AI-assisted development"
        case .waitingForGeneration: return "Waiting on AI"
        case .codeOriented: return "AI-assisted development"
        case .casualChat: return "AI conversation"
        case .researchHeavy: return "AI research session"
        case .unknown: return "AI research session"
        }
    }

    private func fallbackPhrase(context: NoxSemanticContext) -> String {
        if hasDevNearby(context) { return "AI-assisted development" }
        if context.metrics.isWritingHeavy { return "Prompt-writing session" }
        if context.metrics.isReadingHeavy { return "AI research session" }
        return "AI research session"
    }
}
