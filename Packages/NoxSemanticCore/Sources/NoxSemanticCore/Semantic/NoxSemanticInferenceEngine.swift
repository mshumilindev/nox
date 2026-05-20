import Foundation
import NoxCore
import NoxContextCore

public struct NoxSemanticInferenceEngine {
    public init() {}

    private let browserClassifier = NoxBrowserContextClassifier()
    private let aiClassifier = NoxAIWorkflowClassifier()
    private let fusionEngine = NoxContextFusionEngine()

    public func infer(context: NoxSemanticContext) -> NoxSemanticInference {
        let browser = browserClassifier.classify(
            bundleId: context.bundleId,
            windowTitle: context.windowTitle,
            domain: context.domain
        )

        let fusion = fusionEngine.fuse(context: context, browser: browser)

        if fusion.sensitivityLevel == .privateContext || fusion.sensitivityLevel == .sensitive {
            return NoxSemanticInference(
                state: .unknown,
                confidence: fusion.confidence,
                displayPhrase: fusion.phrase,
                reasons: fusion.supportingSignals,
                fusionLabel: fusion.label,
                fusionConfidence: fusion.confidence,
                fusionPhrase: fusion.phrase,
                sensitivityLevel: fusion.sensitivityLevel,
                browserCategory: browser.category,
                aiWorkflow: nil,
                aiWorkflowPhrase: nil,
                shouldSurface: fusion.confidence >= NoxSemanticConfidence.surfaceThreshold
            )
        }

        var reasons: [NoxSemanticReason] = []
        var stateScores: [NoxSemanticState: Double] = [:]
        applyDominantContextBoost(context, stateScores: &stateScores, reasons: &reasons)
        let m = context.metrics
        let passiveViewingContext = NoxSemanticStability.isSustainedPassiveViewing(context, metrics: m)
            || (browser.category == .entertainment && !m.isWritingHeavy)
        let sustainedPassiveUnclearContext = (browser.category == .ambiguous || browser.category == .unknown) &&
            context.timeInCurrentApp >= 20 &&
            !m.isWritingHeavy &&
            m.scrollIntensity < 1.5 &&
            m.typingDensity < 0.8 &&
            m.mouseDensity < 2.5 &&
            (m.isPassive || context.idleSeconds >= 20 || !m.isInteractionActive)
        let comparisonContext = browser.category == .travel ||
            browser.category == .shopping ||
            browser.category == .reviews
        let interactiveFallbackContext = fusion.label == .likelyGaming ||
            fusion.label == .likelyInteractiveBrowsing
        let suppressFragmented = NoxSemanticStability.shouldSuppressFragmentedState(context, metrics: m)

        if context.fragmentationSwitchCount >= 4 &&
            !suppressFragmented &&
            !passiveViewingContext &&
            !comparisonContext &&
            !interactiveFallbackContext {
            stateScores[.fragmentedInteraction, default: 0] += 0.55
            reasons.append(NoxSemanticReason(signal: "switching", detail: "frequent app switches"))
        }

        let suppressWriting = NoxSemanticStability.isSustainedPassiveViewing(context, metrics: m)
            || context.dominantContextType == .watching
            || context.dominantContextType == .listening

        if m.isWritingHeavy, !suppressWriting {
            stateScores[.writing, default: 0] += 0.5
            reasons.append(NoxSemanticReason(signal: "typing", detail: "high typing density"))
        }

        let passiveMediaContext = NoxPassiveMediaContext.indicatesPassiveMedia(
            title: context.windowTitle,
            domain: context.domain,
            browserCategory: browser.category
        )

        if m.isReadingHeavy, !passiveMediaContext {
            stateScores[.reading, default: 0] += 0.5
            reasons.append(NoxSemanticReason(signal: "scroll", detail: "high scroll, low typing"))
        }

        if passiveViewingContext || sustainedPassiveUnclearContext {
            stateScores[.passiveConsumption, default: 0] += 0.7
            reasons.append(
                NoxSemanticReason(
                    signal: passiveViewingContext ? "media_context" : "interaction_shape",
                    detail: passiveViewingContext ? "streaming or video context active" : "sustained low-interaction context"
                )
            )
        } else if m.isPassive || browser.category == .entertainment {
            stateScores[.passiveConsumption, default: 0] += 0.4
        }

        if m.isInteractionActive && !m.isWritingHeavy && !m.isReadingHeavy && !passiveViewingContext {
            stateScores[.activeInteraction, default: 0] += interactiveFallbackContext ? 0.55 : 0.35
        }

        if !m.isInteractionActive && m.interactionIdleSeconds > 15 && context.timeInCurrentApp > 30 {
            stateScores[.waiting, default: 0] += 0.35
            reasons.append(NoxSemanticReason(signal: "idle_gap", detail: "low interaction, app remains active"))
        }

        if context.timeInCurrentApp > 300 && context.recentSwitchCount <= 1 && m.typingDensity > 1 {
            stateScores[.sustainedInteraction, default: 0] += 0.4
        }

        if comparisonContext {
            stateScores[.comparisonActivity, default: 0] += 0.45
        }

        if browser.category == .reviews {
            stateScores[.reviewing, default: 0] += 0.3
        }

        let ai = aiClassifier.assess(context: context)
        if let ai, ai.confidence >= 0.5 {
            switch ai.kind {
            case .passiveAIReading:
                stateScores[.reading, default: 0] += 0.25
            case .promptWriting, .iterativeWorkflow, .codeOriented:
                stateScores[.writing, default: 0] += 0.25
            case .waitingForGeneration:
                stateScores[.waiting, default: 0] += 0.3
            default:
                stateScores[.activeInteraction, default: 0] += 0.15
            }
            reasons.append(contentsOf: ai.reasons)
        }

        let best = stateScores.max(by: { $0.value < $1.value })
        let state = best?.key ?? .unknown
        let confidence = min(0.95, (best?.value ?? 0) + 0.25)

        let inference = NoxSemanticInference(
            state: state,
            confidence: confidence,
            displayPhrase: "",
            reasons: reasons,
            fusionLabel: fusion.label,
            fusionConfidence: fusion.confidence,
            fusionPhrase: fusion.phrase,
            sensitivityLevel: fusion.sensitivityLevel,
            browserCategory: browser.category,
            aiWorkflow: ai?.kind,
            aiWorkflowPhrase: ai?.phrase,
            shouldSurface: NoxSemanticConfidence.shouldSurface(confidence)
        )

        let displayPhrase = NoxSemanticLabelCatalog.liveSignalPhrase(from: inference) ?? ""
        return NoxSemanticInference(
            state: inference.state,
            confidence: inference.confidence,
            displayPhrase: displayPhrase,
            reasons: inference.reasons,
            fusionLabel: inference.fusionLabel,
            fusionConfidence: inference.fusionConfidence,
            fusionPhrase: inference.fusionPhrase,
            sensitivityLevel: inference.sensitivityLevel,
            browserCategory: inference.browserCategory,
            aiWorkflow: inference.aiWorkflow,
            aiWorkflowPhrase: inference.aiWorkflowPhrase,
            shouldSurface: inference.shouldSurface
        )
    }

    private func applyDominantContextBoost(
        _ context: NoxSemanticContext,
        stateScores: inout [NoxSemanticState: Double],
        reasons: inout [NoxSemanticReason]
    ) {
        guard let dominant = context.dominantContextType,
              context.dominantContextConfidence >= 0.45 else { return }
        let boost = min(0.55, context.dominantContextConfidence * 0.6)
        let mapped: NoxSemanticState? = switch dominant {
        case .reading, .research: .reading
        case .writing: .writing
        case .watching, .listening: .passiveConsumption
        case .development, .creativeWork, .fileTransfer: .sustainedInteraction
        case .communication: .activeInteraction
        case .gamingInteractive, .shoppingComparison, .travelPlanning: .activeInteraction
        case .privateContext, .sensitiveContext, .unknown, .insufficient: nil
        }
        guard let mapped else { return }
        let extra: Double = (dominant == .watching || dominant == .listening) ? 0.12 : 0
        stateScores[mapped, default: 0] += boost + extra
        reasons.append(
            NoxSemanticReason(
                signal: "dominant_context",
                detail: "Universal context pipeline: \(dominant.rawValue)"
            )
        )
    }
}
