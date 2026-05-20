import Foundation
import NoxCore

/// Always eligible last-resort adapter when no family-specific adapter produced dominance.
public struct NoxUnknownFallbackContextAdapter: NoxContextAdapter {
    public let adapterId = "unknown-fallback"
    public let reliability = 0.45
    public let priority = 0

    public func matches(input: NoxContextAdapterInput) -> Bool { true }

    public func extract(input: NoxContextAdapterInput) -> NoxContextAdapterEvidence {
        let metrics = input.metrics
        var candidates: [NoxContextCandidate] = []
        var signals: [String] = []

        if input.sensitivityLevel == .privateContext || input.sensitivityLevel == .sensitive {
            candidates.append(
                NoxContextCandidate(
                    id: "\(adapterId)-private",
                    contextType: .privateContext,
                    confidence: 0.85,
                    dominanceWeight: 0.85,
                    sourceAdapterId: adapterId,
                    signalNames: ["sensitivity-gate"]
                )
            )
        } else if metrics.isWritingHeavy {
            candidates.append(fallbackCandidate(.writing, 0.5, ["typing-fallback"]))
        } else if metrics.isReadingHeavy {
            candidates.append(fallbackCandidate(.reading, 0.48, ["scroll-fallback"]))
        } else if metrics.isInteractionActive {
            candidates.append(fallbackCandidate(.gamingInteractive, 0.42, ["interaction-fallback"]))
        } else {
            candidates.append(fallbackCandidate(.insufficient, 0.35, ["insufficient-signals"]))
            signals.append("insufficient-signals")
        }

        return NoxContextAdapterEvidence(
            adapterId: adapterId,
            reliability: reliability,
            candidates: candidates,
            reasons: [.init(category: "fallback", detail: "Unknown or unsupported app — minimal inference", weight: 0.35)],
            supportingSignals: signals
        )
    }

    private func fallbackCandidate(
        _ type: NoxDominantContextType,
        _ confidence: Double,
        _ signalNames: [String]
    ) -> NoxContextCandidate {
        NoxContextCandidate(
            id: "\(adapterId)-\(type.rawValue)",
            contextType: type,
            confidence: confidence,
            dominanceWeight: confidence,
            sourceAdapterId: adapterId,
            signalNames: signalNames
        )
    }
}
