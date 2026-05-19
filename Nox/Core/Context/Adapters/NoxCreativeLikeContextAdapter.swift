import Foundation

struct NoxCreativeLikeContextAdapter: NoxContextAdapter {
    let adapterId = "creative-app"
    let reliability = 0.7
    let priority = 57

    func matches(input: NoxContextAdapterInput) -> Bool {
        let family = NoxAppFamilyResolver.resolve(
            bundleId: input.snapshot.bundleId,
            appName: input.snapshot.appName,
            category: input.activityCategory
        )
        return family == .creative || input.activityCategory == .creative
    }

    func extract(input: NoxContextAdapterInput) -> NoxContextAdapterEvidence {
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
