import Foundation

struct NoxMediaLikeContextAdapter: NoxContextAdapter {
    let adapterId = "media-app"
    let reliability = 0.72
    let priority = 55

    func matches(input: NoxContextAdapterInput) -> Bool {
        NoxAppFamilyResolver.resolve(
            bundleId: input.snapshot.bundleId,
            appName: input.snapshot.appName,
            category: input.activityCategory
        ) == .mediaPlayer
    }

    func extract(input: NoxContextAdapterInput) -> NoxContextAdapterEvidence {
        let metrics = input.metrics
        let passive = metrics.isPassive || input.snapshot.isIdle
        let watching = NoxTitleTokenAnalyzer.hasMediaShapeEvidence(title: input.sanitizedTitle)

        let type: NoxDominantContextType = watching ? .watching : .listening
        var confidence = passive ? 0.78 : 0.62
        var signals = ["media-player-family"]
        if watching { signals.append("media-title-shape") }
        if passive { signals.append("passive-playback") }

        let candidate = NoxContextCandidate(
            id: "\(adapterId)-\(type.rawValue)",
            contextType: type,
            confidence: confidence,
            dominanceWeight: confidence,
            sourceAdapterId: adapterId,
            signalNames: signals
        )

        return NoxContextAdapterEvidence(
            adapterId: adapterId,
            reliability: reliability,
            candidates: [candidate],
            reasons: [.init(category: "app-family", detail: "Media player context", weight: 0.65)],
            supportingSignals: signals
        )
    }
}
