import Foundation

struct NoxCommunicationLikeContextAdapter: NoxContextAdapter {
    let adapterId = "communication"
    let reliability = 0.7
    let priority = 58

    func matches(input: NoxContextAdapterInput) -> Bool {
        let family = NoxAppFamilyResolver.resolve(
            bundleId: input.snapshot.bundleId,
            appName: input.snapshot.appName,
            category: input.activityCategory
        )
        return family == .communication || input.activityCategory == .communication
    }

    func extract(input: NoxContextAdapterInput) -> NoxContextAdapterEvidence {
        var confidence = 0.68
        var signals = ["communication-family"]
        if NoxTitleTokenAnalyzer.hasCommunicationShapeEvidence(title: input.sanitizedTitle) {
            confidence = 0.75
            signals.append("channel-title-shape")
        }
        if input.metrics.isWritingHeavy {
            confidence = min(0.85, confidence + 0.1)
            signals.append("active-messaging")
        }

        let candidate = NoxContextCandidate(
            id: "\(adapterId)-communication",
            contextType: .communication,
            confidence: confidence,
            dominanceWeight: confidence,
            sourceAdapterId: adapterId,
            signalNames: signals
        )

        return NoxContextAdapterEvidence(
            adapterId: adapterId,
            reliability: reliability,
            candidates: [candidate],
            reasons: [.init(category: "app-family", detail: "Communication app", weight: 0.6)],
            supportingSignals: signals
        )
    }
}
