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
            headline = "A familiar context returned after time away."
        } else if thread.totalSessions >= 2 {
            headline = "Repeated \(thread.title.lowercased()) across recent sessions."
        } else {
            headline = "Compatible activity formed a continuity thread."
        }
        return NoxInferenceReason(
            id: "thread-\(thread.id)",
            headline: NoxEmotionalSafetyCopy.sanitize(headline),
            detail: NoxContinuityResurfacingPresenter.threadDetailLine(thread),
            source: .continuityThread
        )
    }

    static func whyReflectionAppeared(_ candidate: NoxReflectionCandidate) -> NoxInferenceReason {
        NoxInferenceReason(
            id: candidate.id,
            headline: NoxEmotionalSafetyCopy.sanitize(candidate.text),
            detail: "Grounded in recent local memory — not advice.",
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

    static func whyMemorySpan(_ span: NoxSemanticMemorySpan) -> NoxInferenceReason {
        let detail = span.sensitivityLevel != .normal
            ? NoxSemanticVisibilityPresenter.mode(for: span.sensitivityLevel).detail
            : "Repeated context stabilized into local memory."
        return NoxInferenceReason(
            id: span.id,
            headline: NoxEmotionalSafetyCopy.sanitize(span.title),
            detail: detail,
            source: .memorySpan
        )
    }
}
