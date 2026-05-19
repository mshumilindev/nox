import Foundation

nonisolated enum NoxAdaptiveInterventionTimingEngine {

    private static let cooldown: TimeInterval = 6 * 3600

    static func evaluate(
        connectorSnapshot: NoxConnectorContinuitySnapshot,
        orchestration: NoxAmbientOrchestrationContext,
        signatures: [NoxBehavioralSignature],
        drift: NoxBehavioralDriftInsight?,
        lastInterventionAt: Date?,
        at date: Date = Date()
    ) -> NoxAmbientIntervention? {
        if let last = lastInterventionAt, date.timeIntervalSince(last) < cooldown {
            return nil
        }

        if orchestration.signals.contains(where: { $0.kind == .returnAfterAbsence && $0.level >= 0.65 }) {
            return intervention(
                id: "intervention-return-adaptive",
                kind: .resurfacingAfterReturn,
                label: "Continuity may feel familiar again.",
                detail: "A calm resurfacing — nothing to act on.",
                at: date
            )
        }

        let base = NoxAmbientInterventionEngine.evaluate(
            transitions: connectorSnapshot.transitions,
            cadencePatterns: connectorSnapshot.cadencePatterns,
            overloadSignals: connectorSnapshot.overloadSignals,
            calendarSignals: connectorSnapshot.generalizedSignals,
            lastInterventionAt: nil,
            at: date
        )

        if let base {
            if shouldSuppress(base: base, orchestration: orchestration, signatures: signatures) {
                return nil
            }
            return base
        }

        if let drift, drift.confidence >= 0.58,
           orchestration.signals.contains(where: { $0.kind == .highInterruptionSensitivity }) {
            return intervention(
                id: "intervention-drift-observe",
                kind: .fragmentedDayAck,
                label: drift.label,
                detail: drift.detail,
                at: date
            )
        }

        if orchestration.signals.contains(where: { $0.kind == .recoveryOpportunityWindow && $0.level >= 0.62 }),
           signatures.contains(where: { $0.kind == .overloadRecoveryOscillation }) {
            return intervention(
                id: "intervention-recovery-adaptive",
                kind: .recoveryAwareShift,
                label: "Rhythm may be shifting toward recovery.",
                detail: "Observed locally — Nox stays quiet unless this repeats.",
                at: date
            )
        }

        return nil
    }

    private static func shouldSuppress(
        base: NoxAmbientIntervention,
        orchestration: NoxAmbientOrchestrationContext,
        signatures: [NoxBehavioralSignature]
    ) -> Bool {
        if base.kind == .fragmentedDayAck,
           orchestration.signals.contains(where: { $0.kind == .deepFocusStability && $0.level >= 0.7 }) {
            return true
        }
        if base.kind == .lateNightCadence,
           signatures.contains(where: { $0.kind == .passiveDecompression }) {
            return true
        }
        return false
    }

    private static func intervention(
        id: String,
        kind: NoxInterventionKind,
        label: String,
        detail: String,
        at date: Date
    ) -> NoxAmbientIntervention {
        NoxAmbientIntervention(
            id: id,
            label: NoxEmotionalSafetyCopy.sanitize(label),
            detail: NoxEmotionalSafetyCopy.sanitize(detail),
            kind: kind,
            observedAt: date
        )
    }
}
