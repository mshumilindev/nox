import Foundation
import NoxCore

public struct NoxCreativeLikeContextAdapter: NoxContextAdapter {
    public let adapterId = "creative-app"
    public let reliability = 0.7
    public let priority = 57

    public func matches(input: NoxContextAdapterInput) -> Bool {
        let family = NoxAppFamilyResolver.resolve(
            bundleId: input.snapshot.bundleId,
            appName: input.snapshot.appName,
            category: input.activityCategory
        )
        return family == .creative || input.activityCategory == .creative
    }

    public func extract(input: NoxContextAdapterInput) -> NoxContextAdapterEvidence {
        var confidence = 0.7
        var signals = ["creative-family"]
        if input.metrics.isInteractionActive {
            confidence = 0.78
            signals.append("canvas-interaction")
        }

        let candidate = NoxContextCandidate(
            id: "\(adapterId)-creative",
            contextType: .creativeWork,
            confidence: confidence,
            dominanceWeight: confidence,
            sourceAdapterId: adapterId,
            signalNames: signals
        )

        return NoxContextAdapterEvidence(
            adapterId: adapterId,
            reliability: reliability,
            candidates: [candidate],
            reasons: [.init(category: "app-family", detail: "Creative tool context", weight: 0.62)],
            supportingSignals: signals
        )
    }
}
