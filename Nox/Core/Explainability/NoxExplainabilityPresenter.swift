import Foundation

enum NoxExplainabilityPresenter {

    static func whySeeingLiveContext(
        inference: NoxSemanticInference,
        awareness: NoxAwarenessSnapshot
    ) -> NoxInferenceReason? {
        guard inference.shouldSurface else { return nil }
        let headline = NoxEmotionalSafetyCopy.sanitize(
            inference.displayPhrase.isEmpty
                ? awareness.scopeLabel
                : inference.displayPhrase
        )
        return NoxInferenceReason(
            id: "live-context",
            headline: headline,
            detail: awareness.confidenceLine,
            source: .liveSignal
        )
    }

    static func whyContinuityAppeared(thread: NoxContinuityThread) -> NoxInferenceReason {
        let headline: String
        if thread.totalResumptions > 0 {
            headline = "Repeated activity returned after time away."
        } else if thread.totalSessions >= 2 {
            headline = "Repeated \(thread.title.lowercased()) across recent sessions."
        } else {
            headline = "Repeated activity formed a recurring thread."
        }
        return NoxInferenceReason(
            id: "thread-\(thread.id)",
            headline: NoxEmotionalSafetyCopy.sanitize(headline),
            detail: NoxContinuityResurfacingPresenter.threadDetailLine(thread),
            source: .continuityThread
        )
    }

    static func whyReflectionAppeared(_ candidate: NoxReflectionCandidate) -> NoxInferenceReason {
        let detail = candidate.detailLine.isEmpty
            ? NoxReflectionPresenter.defaultDetailLine
            : candidate.detailLine
        return NoxInferenceReason(
            id: candidate.id,
            headline: NoxEmotionalSafetyCopy.sanitize(candidate.text),
            detail: NoxEmotionalSafetyCopy.sanitize(detail),
            source: .reflection
        )
    }

    static func whyEmerging(_ observation: NoxEmergingMemoryObservation) -> NoxInferenceReason {
        NoxInferenceReason(
            id: observation.id,
            headline: NoxEmotionalSafetyCopy.sanitize(observation.title),
            detail: observation.detail,
            source: .emergence
        )
    }

    static func whyConnectorSignal(_ snapshot: NoxConnectorContinuitySnapshot) -> NoxInferenceReason? {
        NoxConnectorExplainability.inferenceReason(for: snapshot)
    }

    static func whySystemContradiction(_ intervention: NoxAmbientIntervention) -> NoxInferenceReason? {
        guard intervention.kind == .systemState else { return nil }
        let detail = intervention.explainabilityDetail
            ?? NoxSystemContradictionPresenter.explainabilityDetail
        return NoxInferenceReason(
            id: "system-\(intervention.id)",
            headline: NoxEmotionalSafetyCopy.sanitize(intervention.label),
            detail: NoxEmotionalSafetyCopy.sanitize(detail),
            source: .liveSignal
        )
    }

    static func whyMemorySpan(_ span: NoxSemanticMemorySpan) -> NoxInferenceReason {
        let detail = span.sensitivityLevel != .normal
            ? NoxSemanticVisibilityPresenter.mode(for: span.sensitivityLevel).detail
            : "Repeated activity stabilized into local memory."
        return NoxInferenceReason(
            id: span.id,
            headline: NoxEmotionalSafetyCopy.sanitize(span.title),
            detail: detail,
            source: .memorySpan
        )
    }
}
