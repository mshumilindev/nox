import Foundation

struct NoxEditorLikeContextAdapter: NoxContextAdapter {
    let adapterId = "editor"
    let reliability = 0.75
    let priority = 60

    func matches(input: NoxContextAdapterInput) -> Bool {
        let family = NoxAppFamilyResolver.resolve(
            bundleId: input.snapshot.bundleId,
            appName: input.snapshot.appName,
            category: input.activityCategory
        )
        return family == .editor || input.activityCategory == .development
    }

    func extract(input: NoxContextAdapterInput) -> NoxContextAdapterEvidence {
        var candidates: [NoxContextCandidate] = []
        let metrics = input.metrics
        let title = input.sanitizedTitle

        if metrics.isWritingHeavy || metrics.typingDensity > 1 {
            candidates.append(make(.development, 0.78, ["editor-typing"]))
            candidates.append(make(.writing, 0.65, ["editor-writing"]))
        } else if metrics.isPassive && input.stableDurationSeconds > 30 {
            candidates.append(make(.development, 0.55, ["editor-stable-passive"]))
        } else {
            candidates.append(make(.development, 0.6, ["editor-default"]))
        }

        if NoxTitleTokenAnalyzer.hasProjectShapeEvidence(title: title) {
            candidates.append(make(.development, 0.7, ["project-title-shape"]))
        }

        return NoxContextAdapterEvidence(
            adapterId: adapterId,
            reliability: reliability,
            candidates: candidates,
            reasons: [.init(category: "app-family", detail: "Editor/IDE-shaped app", weight: 0.65)],
            supportingSignals: ["editor-family"]
        )
    }

    private func make(_ type: NoxDominantContextType, _ confidence: Double, _ signals: [String]) -> NoxContextCandidate {
        NoxContextCandidate(
            id: "\(adapterId)-\(type.rawValue)",
            contextType: type,
            confidence: confidence,
            dominanceWeight: confidence,
            sourceAdapterId: adapterId,
            signalNames: signals
        )
    }
}
