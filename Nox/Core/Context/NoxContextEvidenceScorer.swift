import Foundation

struct NoxContextEvidenceScorer: Sendable {
    func score(
        adapterEvidence: [NoxContextAdapterEvidence],
        input: NoxContextAdapterInput
    ) -> [NoxContextCandidate] {
        var merged: [NoxDominantContextType: NoxContextCandidate] = [:]

        for evidence in adapterEvidence {
            for candidate in evidence.candidates {
                let weighted = weightedConfidence(
                    candidate: candidate,
                    adapterReliability: evidence.reliability,
                    input: input
                )
                if let existing = merged[candidate.contextType] {
                    if weighted > existing.confidence {
                        merged[candidate.contextType] = NoxContextCandidate(
                            id: candidate.id,
                            contextType: candidate.contextType,
                            confidence: weighted,
                            dominanceWeight: weighted * dominanceMultiplier(for: candidate.contextType, input: input),
                            sourceAdapterId: candidate.sourceAdapterId,
                            signalNames: existing.signalNames + candidate.signalNames
                        )
                    }
                } else {
                    merged[candidate.contextType] = NoxContextCandidate(
                        id: candidate.id,
                        contextType: candidate.contextType,
                        confidence: weighted,
                        dominanceWeight: weighted * dominanceMultiplier(for: candidate.contextType, input: input),
                        sourceAdapterId: candidate.sourceAdapterId,
                        signalNames: candidate.signalNames
                    )
                }
            }
        }

        return merged.values.sorted { $0.dominanceWeight > $1.dominanceWeight }
    }

    private func weightedConfidence(
        candidate: NoxContextCandidate,
        adapterReliability: Double,
        input: NoxContextAdapterInput
    ) -> Double {
        var score = candidate.confidence * adapterReliability

        let metrics = input.metrics
        switch candidate.contextType {
        case .writing, .development:
            if metrics.isWritingHeavy { score += 0.12 }
            if input.stableDurationSeconds > 45 { score += 0.06 }
        case .reading, .research:
            if metrics.isReadingHeavy { score += 0.1 }
        case .watching, .listening:
            if metrics.isPassive { score += 0.1 }
            if input.stableDurationSeconds > 60 { score += 0.08 }
        case .communication:
            if metrics.typingDensity > 0.5 { score += 0.06 }
        case .gamingInteractive:
            if metrics.isInteractionActive { score += 0.08 }
        case .fileTransfer:
            if NoxTitleTokenAnalyzer.hasTransferShapeEvidence(title: input.sanitizedTitle) {
                score += 0.1
            }
        case .privateContext, .sensitiveContext:
            score = max(score, 0.8)
        default:
            break
        }

        if !input.capabilities.windowAware {
            score *= 0.85
        }
        if input.sensitivityLevel != .normal {
            score = min(score, 0.75)
        }

        return min(0.98, max(0.05, score))
    }

    private func dominanceMultiplier(
        for type: NoxDominantContextType,
        input: NoxContextAdapterInput
    ) -> Double {
        let stable = input.stableDurationSeconds
        switch type {
        case .watching, .listening:
            return stable > 90 && input.metrics.isPassive ? 1.15 : 1.0
        case .writing, .development:
            return input.metrics.isWritingHeavy && stable > 30 ? 1.12 : 1.0
        case .creativeWork:
            return input.metrics.isInteractionActive && stable > 40 ? 1.1 : 1.0
        default:
            return 1.0
        }
    }
}
