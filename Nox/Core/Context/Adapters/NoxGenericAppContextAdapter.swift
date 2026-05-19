import Foundation

/// Shape-based signals for utility/document apps — not the universal fallback.
struct NoxGenericAppContextAdapter: NoxContextAdapter {
    let adapterId = "generic-app"
    let reliability = 0.58
    let priority = 8

    func matches(input: NoxContextAdapterInput) -> Bool {
        let family = NoxAppFamilyResolver.resolve(
            bundleId: input.snapshot.bundleId,
            appName: input.snapshot.appName,
            category: input.activityCategory
        )
        switch family {
        case .utility, .document, .fileManager, .unknown:
            return true
        default:
            return false
        }
    }

    func extract(input: NoxContextAdapterInput) -> NoxContextAdapterEvidence {
        var candidates: [NoxContextCandidate] = []
        var reasons: [NoxContextReason] = []
        var signals: [String] = []
        let metrics = input.metrics
        let title = input.sanitizedTitle

        if input.sensitivityLevel == .privateContext || input.sensitivityLevel == .sensitive {
            candidates.append(candidate(.privateContext, 0.85, ["sensitivity-gate"]))
            reasons.append(.init(category: "sensitivity", detail: "Elevated sensitivity", weight: 0.9))
            return evidence(candidates: candidates, reasons: reasons, signals: signals)
        }

        if metrics.isWritingHeavy {
            candidates.append(candidate(.writing, 0.68, ["typing-density-high"]))
        } else if metrics.isReadingHeavy {
            candidates.append(candidate(.reading, 0.62, ["scroll-without-typing"]))
        }

        if let title, NoxTitleTokenAnalyzer.hasDocumentShapeEvidence(title: title) {
            candidates.append(candidate(.reading, 0.58, ["document-title-shape"]))
            signals.append("document-shape")
        }

        switch input.activityCategory {
        case .productivity:
            candidates.append(candidate(.writing, 0.42, ["app-category-productivity"]))
        case .system, .systemInternal:
            candidates.append(candidate(.unknown, 0.4, ["system-utility"]))
        default:
            break
        }

        if candidates.isEmpty {
            candidates.append(candidate(.unknown, 0.38, ["generic-app-signals"]))
        }

        reasons.append(.init(category: "app-family", detail: "Generic utility/document app", weight: 0.45))
        return evidence(candidates: candidates, reasons: reasons, signals: signals)
    }

    private func candidate(
        _ type: NoxDominantContextType,
        _ confidence: Double,
        _ signals: [String]
    ) -> NoxContextCandidate {
        NoxContextCandidate(
            id: "\(adapterId)-\(type.rawValue)",
            contextType: type,
            confidence: confidence,
            dominanceWeight: confidence,
            sourceAdapterId: adapterId,
            signalNames: signals
        )
    }

    private func evidence(
        candidates: [NoxContextCandidate],
        reasons: [NoxContextReason],
        signals: [String]
    ) -> NoxContextAdapterEvidence {
        NoxContextAdapterEvidence(
            adapterId: adapterId,
            reliability: reliability,
            candidates: candidates,
            reasons: reasons,
            supportingSignals: signals
        )
    }
}
