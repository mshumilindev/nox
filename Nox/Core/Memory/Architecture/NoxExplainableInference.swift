import Foundation

/// Internal explainability contract — every semantic conclusion must be traceable.
struct NoxExplainableSignal: Codable, Equatable, Sendable {
    let signal: String
    let detail: String
    let weight: Double

    init(signal: String, detail: String, weight: Double = 1.0) {
        self.signal = signal
        self.detail = detail
        self.weight = weight
    }

    init(from reason: NoxSemanticReason, weight: Double = 1.0) {
        self.signal = reason.signal
        self.detail = reason.detail
        self.weight = weight
    }
}

struct NoxExplainableInference: Equatable, Sendable {
    let conclusion: String
    let confidence: Double
    let supportingSignals: [NoxExplainableSignal]
    let reasoningChain: [String]

    var isExplainable: Bool {
        !supportingSignals.isEmpty && !reasoningChain.isEmpty
    }

    static func from(
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
