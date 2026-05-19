import Foundation

nonisolated enum NoxContinuityNudgeEngine {

    static func build(
        unfinished: [NoxUnfinishedContinuityCandidate],
        structural: [NoxStructuralContinuityWeight],
        decompression: NoxDecompressionState,
        recovery: NoxRecoveryWindowModel,
        behavioral: NoxBehavioralIntelligenceSnapshot,
        receptiveness: NoxInterventionReceptiveness
    ) -> [NoxContextualNudge] {
        var nudges: [NoxContextualNudge] = []

        if decompression.inDecompression {
            nudges.append(nudge(
                id: "nudge-decompression-silence",
                kind: .decompressionSilence,
                line: "Nox is staying quieter while things settle.",
                detail: "Resurfacing is reduced for now — nothing to act on.",
                confidence: 0.62
            ))
        }

        if let top = unfinished.first, top.persistenceScore >= 0.55 {
            nudges.append(nudge(
                id: "nudge-unfinished-\(top.id)",
                kind: .unfinishedContinuity,
                line: top.detail,
                detail: nil,
                confidence: min(0.72, top.persistenceScore + 0.12)
            ))
        }

        if recovery.isOpen {
            nudges.append(nudge(
                id: "nudge-recovery-window",
                kind: .recoveryWindow,
                line: recovery.detail,
                detail: nil,
                confidence: recovery.confidence
            ))
        }

        if behavioral.signatures.contains(where: { $0.kind == .fragmentedContext }),
           receptiveness.fragmented {
            nudges.append(nudge(
                id: "nudge-fragmentation-loop",
                kind: .fragmentationLoop,
                line: "Continuity has been breaking apart often — Nox is holding observations lightly.",
                detail: nil,
                confidence: 0.57
            ))
        }

        if let recurring = structural.first(where: { $0.kind == .recurringReturn && $0.weight >= 0.55 }) {
            nudges.append(nudge(
                id: "nudge-recurring-\(recurring.subjectId)",
                kind: .recurringStructure,
                line: "\(recurring.label) keeps returning as a through-line.",
                detail: nil,
                confidence: 0.56
            ))
        }

        if let ignored = structural.first(where: { $0.kind == .unresolved && $0.weight >= 0.5 }) {
            nudges.append(nudge(
                id: "nudge-ignored-\(ignored.subjectId)",
                kind: .ignoredStructure,
                line: "\(ignored.label) remains open across recent sessions.",
                detail: nil,
                confidence: 0.55
            ))
        }

        return nudges.sorted { $0.confidence > $1.confidence }
    }

    private static func nudge(
        id: String,
        kind: NoxContextualNudgeKind,
        line: String,
        detail: String?,
        confidence: Double
    ) -> NoxContextualNudge {
        NoxContextualNudge(
            id: id,
            kind: kind,
            line: NoxEmotionalSafetyCopy.sanitize(line),
            detail: detail.map { NoxEmotionalSafetyCopy.sanitize($0) },
            confidence: confidence
        )
    }
}
