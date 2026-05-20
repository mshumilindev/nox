import Foundation

nonisolated enum NoxInterventionSubtletyPass {

    private static let extendedCooldown: TimeInterval = 8 * 3600

    static func refine(
        _ intervention: NoxAmbientIntervention?,
        context: NoxContinuityMaturityContext,
        signatures: [NoxBehavioralSignature],
        lastInterventionAt: Date?,
        at date: Date = Date()
    ) -> NoxAmbientIntervention? {
        guard var intervention else { return nil }

        if let last = lastInterventionAt {
            let elapsed = date.timeIntervalSince(last)
            if intervention.kind == .fragmentedDayAck, elapsed < extendedCooldown {
                return nil
            }
            if elapsed < 4 * 3600 { return nil }
        }

        if context.isDeepFocus, intervention.kind == .fragmentedDayAck {
            return nil
        }

        if signatures.contains(where: { $0.kind == .passiveDecompression }),
           intervention.kind == .lateNightCadence {
            return nil
        }

        if context.overloadElevated, intervention.kind == .recoveryAwareShift {
            return soften(intervention, label: "The week may be easing.", detail: "Quieter stretches are showing up — no action needed.")
        }

        switch intervention.kind {
        case .resurfacingAfterReturn:
            intervention = soften(
                intervention,
                label: "A recurring workflow may be returning.",
                detail: "A quiet note from local memory — easy to ignore."
            )
        case .fragmentedDayAck:
            intervention = soften(
                intervention,
                label: "The day has felt scattered.",
                detail: "Noticed on this Mac — not a warning."
            )
        case .recoveryAwareShift:
            intervention = soften(
                intervention,
                label: "Rhythm may be loosening.",
                detail: "Nox stays quiet unless this repeats."
            )
        case .lateNightCadence:
            intervention = soften(
                intervention,
                label: "Evenings have been active again.",
                detail: "A small recognition — not coaching."
            )
        case .systemState:
            return intervention
        }

        return intervention
    }

    private static func soften(
        _ intervention: NoxAmbientIntervention,
        label: String,
        detail: String
    ) -> NoxAmbientIntervention {
        NoxAmbientIntervention(
            id: intervention.id,
            label: NoxEmotionalSafetyCopy.sanitize(label),
            detail: NoxEmotionalSafetyCopy.sanitize(detail),
            kind: intervention.kind,
            observedAt: intervention.observedAt,
            systemContradictionType: intervention.systemContradictionType,
            explainabilityDetail: intervention.explainabilityDetail,
            assuranceLine: intervention.assuranceLine,
            actions: intervention.actions
        )
    }
}
