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
import NoxShrineCore

nonisolated enum NoxOrchestrationSignalLayer {

    static func build(
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        connectorSnapshot: NoxConnectorContinuitySnapshot,
        signatures: [NoxBehavioralSignature],
        drift: NoxBehavioralDriftInsight?,
        at date: Date = Date()
    ) -> NoxAmbientOrchestrationContext {
        var signals: [NoxOrchestrationSignal] = []
        let switches = max(stats.appSwitchCount, focus?.switchCount ?? 0)

        if switches >= 10 || focus?.kind == .fragmented {
            signals.append(signal(.highInterruptionSensitivity, level: 0.72, note: "Fragmentation elevated"))
        }

        if focus?.kind == .deepWork, (focus?.uninterruptedMs ?? 0) >= 45 * 60_000 {
            signals.append(signal(.deepFocusStability, level: 0.75, note: "Deep focus stable"))
        }

        if connectorSnapshot.overloadSignals.count >= 2
            || signatures.contains(where: { $0.kind == .overloadRecoveryOscillation }) {
            signals.append(signal(.overloadRiskElevation, level: 0.68, note: "Overload signals present"))
        }

        if signatures.contains(where: { $0.kind == .passiveDecompression })
            || connectorSnapshot.cadencePatterns.contains(where: { $0.id == "rhythm-recovery" }) {
            signals.append(signal(.recoveryOpportunityWindow, level: 0.62, note: "Recovery window may be open"))
        }

        if switches <= 5, focus?.kind != .fragmented, stats.fragmentedMs < stats.focusedMs {
            signals.append(signal(.lowFragmentationWindow, level: 0.6, note: "Low fragmentation window"))
        }

        if connectorSnapshot.transitions.contains(where: { $0.kind == .returningAfterAbsence }) {
            signals.append(signal(.returnAfterAbsence, level: 0.7, note: "Return after absence"))
        }

        if drift != nil {
            signals.append(signal(.highInterruptionSensitivity, level: 0.55, note: "Rhythm drift observed"))
        }

        _ = date
        return NoxAmbientOrchestrationContext(signals: signals, generatedAt: date)
    }

    private static func signal(
        _ kind: NoxOrchestrationSignalKind,
        level: Double,
        note: String
    ) -> NoxOrchestrationSignal {
        NoxOrchestrationSignal(
            id: "orch-\(kind.rawValue)",
            kind: kind,
            level: min(1, max(0, level)),
            note: note
        )
    }
}
