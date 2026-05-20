import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

/// Internal explainability contract — every semantic conclusion must be traceable.
public struct NoxExplainableSignal: Codable, Equatable, Sendable {
    public let signal: String
    public let detail: String
    public let weight: Double

    public init(signal: String, detail: String, weight: Double = 1.0) {
        self.signal = signal
        self.detail = detail
        self.weight = weight
    }

    public init(from reason: NoxSemanticReason, weight: Double = 1.0) {
        self.signal = reason.signal
        self.detail = reason.detail
        self.weight = weight
    }
}

public struct NoxExplainableInference: Equatable, Sendable {
    public let conclusion: String
    public let confidence: Double
    public let supportingSignals: [NoxExplainableSignal]
    public let reasoningChain: [String]

    public init(
        conclusion: String,
        confidence: Double,
        supportingSignals: [NoxExplainableSignal],
        reasoningChain: [String]
    ) {
        self.conclusion = conclusion
        self.confidence = confidence
        self.supportingSignals = supportingSignals
        self.reasoningChain = reasoningChain
    }

    public var isExplainable: Bool {
        !supportingSignals.isEmpty && !reasoningChain.isEmpty
    }

    public static func from(
        inference: NoxSemanticInference,
        conclusion: String? = nil
    ) -> NoxExplainableInference {
        let resolved = conclusion ?? inference.displayPhrase
        var chain: [String] = []
        if inference.confidence >= NoxSemanticConfidence.surfaceThreshold {
            chain.append("confidence above surface threshold")
        }
        for reason in inference.reasons {
            chain.append("\(reason.signal): \(reason.detail)")
        }
        if !inference.fusionPhrase.isEmpty {
            chain.append("fusion: \(inference.fusionPhrase)")
        }
        return NoxExplainableInference(
            conclusion: resolved,
            confidence: inference.confidence,
            supportingSignals: inference.reasons.map { NoxExplainableSignal(from: $0) },
            reasoningChain: chain
        )
    }
}
