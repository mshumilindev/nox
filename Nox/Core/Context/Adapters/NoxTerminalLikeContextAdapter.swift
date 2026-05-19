import Foundation

struct NoxTerminalLikeContextAdapter: NoxContextAdapter {
    let adapterId = "terminal"
    let reliability = 0.78
    let priority = 65

    func matches(input: NoxContextAdapterInput) -> Bool {
        NoxAppFamilyResolver.resolve(
            bundleId: input.snapshot.bundleId,
            appName: input.snapshot.appName,
            category: input.activityCategory
        ) == .terminal
    }

    func extract(input: NoxContextAdapterInput) -> NoxContextAdapterEvidence {
        let metrics = input.metrics
        var confidence = 0.72
        var signals = ["terminal-family"]

        if metrics.isWritingHeavy || metrics.typingDensity > 0.8 {
            confidence = 0.82
            signals.append("terminal-typing")
        }
        if NoxTitleTokenAnalyzer.hasProjectShapeEvidence(title: input.sanitizedTitle) {
            confidence = min(0.9, confidence + 0.08)
            signals.append("build-project-title")
        }

        let candidate = NoxContextCandidate(
            id: "\(adapterId)-development",
            contextType: .development,
            confidence: confidence,
            dominanceWeight: confidence,
            sourceAdapterId: adapterId,
            signalNames: signals
        )

        return NoxContextAdapterEvidence(
            adapterId: adapterId,
            reliability: reliability,
            candidates: [candidate],
            reasons: [.init(category: "app-family", detail: "Terminal/shell context", weight: 0.7)],
            supportingSignals: signals
        )
    }
}
