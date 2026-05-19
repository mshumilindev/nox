import Foundation

nonisolated enum NoxContinuitySalience: String, Sendable {
    case stable
    case returning
    case fading
    case unresolved
    case fragile
    case quiet
    case heavy
}

nonisolated struct NoxContinuityGravityScore: Equatable, Sendable {
    let subjectKey: String
    let gravity: Double
    let salience: NoxContinuitySalience
}

nonisolated struct NoxContinuityMaturityContext: Equatable, Sendable {
    let input: NoxReflectionInput
    let focus: NoxFocusAnalysis?
    let behavioral: NoxBehavioralIntelligenceSnapshot
    let orchestration: NoxAmbientOrchestrationContext
    let isFragmented: Bool
    let isDeepFocus: Bool
    let overloadElevated: Bool

    static func build(
        input: NoxReflectionInput,
        focus: NoxFocusAnalysis?,
        behavioral: NoxBehavioralIntelligenceSnapshot,
        connectorSnapshot: NoxConnectorContinuitySnapshot
    ) -> NoxContinuityMaturityContext {
        let orchestration = behavioral.orchestration
        let fragmented = focus?.kind == .fragmented
            || input.focusSummary == "fragmented attention"
            || input.fragmentedSessions >= 2
        let deepFocus = focus?.kind == .deepWork
            || orchestration.signals.contains(where: { $0.kind == .deepFocusStability && $0.level >= 0.65 })
        let overload = !connectorSnapshot.overloadSignals.isEmpty
            || orchestration.signals.contains(where: { $0.kind == .overloadRiskElevation && $0.level >= 0.55 })
        return NoxContinuityMaturityContext(
            input: input,
            focus: focus,
            behavioral: behavioral,
            orchestration: orchestration,
            isFragmented: fragmented,
            isDeepFocus: deepFocus,
            overloadElevated: overload
        )
    }
}

nonisolated struct NoxMaturedReflection: Equatable, Sendable {
    let candidate: NoxReflectionCandidate
    let gravity: Double
    let salience: NoxContinuitySalience
}
