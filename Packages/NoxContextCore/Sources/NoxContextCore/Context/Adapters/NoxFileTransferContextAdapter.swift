import Foundation
import NoxCore

public struct NoxFileTransferContextAdapter: NoxContextAdapter {
    public let adapterId = "file-transfer"
    public let reliability = 0.76
    public let priority = 44

    public func matches(input: NoxContextAdapterInput) -> Bool {
        if NoxTitleTokenAnalyzer.hasTransferShapeEvidence(title: input.sanitizedTitle) {
            return true
        }
        let family = NoxAppFamilyResolver.resolve(
            bundleId: input.snapshot.bundleId,
            appName: input.snapshot.appName,
            category: input.activityCategory
        )
        return family == .fileManager && input.metrics.isPassive
    }

    public func extract(input: NoxContextAdapterInput) -> NoxContextAdapterEvidence {
        var confidence = 0.74
        var signals = ["transfer-shape"]
        if input.metrics.isPassive {
            confidence += 0.06
            signals.append("passive-transfer")
        }

        let candidate = NoxContextCandidate(
            id: "\(adapterId)-transfer",
            contextType: .fileTransfer,
            confidence: min(0.9, confidence),
            dominanceWeight: min(0.9, confidence),
            sourceAdapterId: adapterId,
            signalNames: signals
        )

        return NoxContextAdapterEvidence(
            adapterId: adapterId,
            reliability: reliability,
            candidates: [candidate],
            reasons: [.init(category: "title", detail: "Download or transfer activity shape", weight: 0.68)],
            supportingSignals: signals
        )
    }
}
