import Foundation
import NoxCore

public struct NoxBrowserLikeContextAdapter: NoxContextAdapter {
    public let adapterId = "browser"
    public let reliability = 0.7
    public let priority = 50

    public func matches(input: NoxContextAdapterInput) -> Bool {
        NoxAppFamilyResolver.resolve(
            bundleId: input.snapshot.bundleId,
            appName: input.snapshot.appName,
            category: input.activityCategory
        ) == .browser
    }

    public func extract(input: NoxContextAdapterInput) -> NoxContextAdapterEvidence {
        var candidates: [NoxContextCandidate] = []
        var signals: [String] = []
        let title = input.sanitizedTitle
        let metrics = input.metrics
        let mediaContext = NoxPassiveMediaContext.indicatesPassiveMedia(
            title: title,
            domain: input.domain,
            browserCategory: nil
        ) || NoxPassiveMediaContext.isStreamingHost(input.domain?.lowercased() ?? "")

        if mediaContext {
            candidates.append(make(.watching, 0.74, ["passive-media-context"]))
            signals.append("passive-media-context")
        } else if NoxTitleTokenAnalyzer.hasMediaShapeEvidence(title: title) {
            candidates.append(make(.watching, 0.68, ["media-title-shape"]))
            signals.append("media-shaped-title")
        } else if NoxTitleTokenAnalyzer.hasPassiveContentShapeEvidence(title: title), metrics.isPassive {
            candidates.append(make(.watching, 0.7, ["passive-content-shape"]))
            signals.append("passive-content-title")
        }

        if input.stableDurationSeconds >= 20,
           metrics.isPassive,
           !metrics.isWritingHeavy {
            candidates.append(make(.watching, 0.72, ["sustained-passive-browser"]))
            signals.append("stable-passive-browser")
        }

        if metrics.isWritingHeavy {
            candidates.append(make(.writing, 0.7, ["browser-typing"]))
        } else if metrics.isReadingHeavy, !mediaContext {
            candidates.append(make(.reading, 0.68, ["browser-scroll"]))
        } else if metrics.isPassive || mediaContext {
            candidates.append(make(.watching, 0.64, ["browser-passive-viewing"]))
            signals.append("browser-passive-viewing")
        }

        if metrics.isInteractionActive && !metrics.isWritingHeavy, !mediaContext {
            candidates.append(make(.shoppingComparison, 0.42, ["browser-active-interaction"]))
            candidates.append(make(.research, 0.4, ["browser-active-research"]))
        }

        if input.domain != nil {
            signals.append("domain-available")
        }

        if candidates.isEmpty {
            candidates.append(make(.research, 0.45, ["browser-default"]))
        }

        return NoxContextAdapterEvidence(
            adapterId: adapterId,
            reliability: reliability,
            candidates: candidates,
            reasons: [.init(category: "app-family", detail: "Browser-shaped app", weight: 0.6)],
            supportingSignals: signals
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
