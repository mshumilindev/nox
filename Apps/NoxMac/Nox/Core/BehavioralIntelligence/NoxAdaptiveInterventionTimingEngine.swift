import Foundation
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore

nonisolated enum NoxAdaptiveInterventionTimingEngine {

    private static let cooldown: TimeInterval = 6 * 3600

    static func evaluate(
        connectorSnapshot: NoxConnectorContinuitySnapshot,
        orchestration: NoxAmbientOrchestrationContext,
        signatures: [NoxBehavioralSignature],
        drift: NoxBehavioralDriftInsight?,
        lastInterventionAt: Date?,
        focus: NoxFocusAnalysis? = nil,
        reflectionInput: NoxReflectionInput? = nil,
        at date: Date = Date()
    ) -> NoxAmbientIntervention? {
        if let last = lastInterventionAt, date.timeIntervalSince(last) < cooldown {
            return nil
        }

        let maturityContext = NoxContinuityMaturityContext.build(
            input: reflectionInput ?? .empty,
            focus: focus,
            behavioral: NoxBehavioralIntelligenceSnapshot(
                signatures: signatures,
                expectations: nil,
                continuityWeights: [],
                temporalRhythms: [],
                lifeStructures: [],
                drift: drift,
                orchestration: orchestration,
                enrichmentNotes: [],
                prioritizedThreadIds: [],
                prioritizedArcIds: [],
                recommendedIntervention: nil
            ),
            connectorSnapshot: connectorSnapshot
        )

        var result: NoxAmbientIntervention?

        if orchestration.signals.contains(where: { $0.kind == .returnAfterAbsence && $0.level >= 0.72 }) {
            result = intervention(
                id: "intervention-return-adaptive",
                kind: .resurfacingAfterReturn,
                label: "A recurring workflow may be returning.",
                detail: "A calm resurfacing — nothing to act on.",
                at: date
            )
        }

        if result == nil {
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
                result = nil
            } else {
                result = base
            }
        }

        if result == nil,
           let drift, drift.confidence >= 0.62,
           orchestration.signals.contains(where: { $0.kind == .highInterruptionSensitivity && $0.level >= 0.62 }) {
            result = intervention(
                id: "intervention-drift-observe",
                kind: .fragmentedDayAck,
                label: drift.label,
                detail: drift.detail,
                at: date
            )
        }

        if result == nil,
           orchestration.signals.contains(where: { $0.kind == .recoveryOpportunityWindow && $0.level >= 0.68 }),
           signatures.contains(where: { $0.kind == .overloadRecoveryOscillation }) {
            result = intervention(
                id: "intervention-recovery-adaptive",
                kind: .recoveryAwareShift,
                label: "Rhythm may be shifting toward recovery.",
                detail: "Observed locally — Nox stays quiet unless this repeats.",
                at: date
            )
        }
        }

        return NoxInterventionSubtletyPass.refine(
            result,
            context: maturityContext,
            signatures: signatures,
            lastInterventionAt: lastInterventionAt,
            at: date
        )
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
