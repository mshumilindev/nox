import Foundation
import NoxCore

public struct NoxGameContextAdapter: NoxContextAdapter {
    public let adapterId = "game"
    public let reliability = 0.74
    public let priority = 42

    public func matches(input: NoxContextAdapterInput) -> Bool {
        let family = NoxAppFamilyResolver.resolve(
            bundleId: input.snapshot.bundleId,
            appName: input.snapshot.appName,
            category: input.activityCategory
        )
        return family == .game || input.activityCategory == .entertainment
    }

    public func extract(input: NoxContextAdapterInput) -> NoxContextAdapterEvidence {
        let metrics = input.metrics
        var confidence = 0.72
        var signals = ["game-family"]

        if metrics.isInteractionActive && !metrics.isWritingHeavy {
            confidence = 0.8
            signals.append("active-non-writing")
        }
        if input.stableDurationSeconds >= 30 {
            confidence += 0.05
            signals.append("sustained-session")
        }

        let candidate = NoxContextCandidate(
            id: "\(adapterId)-gaming",
            contextType: .gamingInteractive,
            confidence: min(0.92, confidence),
            dominanceWeight: min(0.92, confidence),
            sourceAdapterId: adapterId,
            signalNames: signals
        )

        return NoxContextAdapterEvidence(
            adapterId: adapterId,
            reliability: reliability,
            candidates: [candidate],
            reasons: [.init(category: "app-family", detail: "Game or interactive entertainment app", weight: 0.7)],
            supportingSignals: signals
        )
    }
}
