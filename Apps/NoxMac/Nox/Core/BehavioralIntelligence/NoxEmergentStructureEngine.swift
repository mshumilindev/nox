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

nonisolated enum NoxEmergentStructureEngine {

    static func candidates(
        signatures: [NoxBehavioralSignature],
        arcs: [NoxSemanticArc],
        monthlyRollups: [NoxMemoryRollupSnapshot],
        expectations: NoxExpectedRhythmModel?
    ) -> [NoxLifeStructureCandidate] {
        var results: [NoxLifeStructureCandidate] = []

        if signatures.contains(where: { $0.kind == .creativeExploration }) {
            results.append(candidate(
                id: "structure-creative-phase",
                label: "Extended creation phase",
                detail: "Creative tools have had recurring presence — soft and revisable.",
                confidence: 0.56
            ))
        }

        if signatures.contains(where: { $0.kind == .coordinationHeavyWeek }) {
            results.append(candidate(
                id: "structure-coordination-era",
                label: "Coordination-heavy era",
                detail: "Scheduling and communication may be shaping this stretch of time.",
                confidence: 0.58
            ))
        }

        if signatures.contains(where: { $0.kind == .fragmentedContext || $0.kind == .instabilityPhase }) {
            results.append(candidate(
                id: "structure-fragmented-transition",
                label: "Fragmented transition period",
                detail: "Continuity has been scattered across many short contexts.",
                confidence: 0.6
            ))
        }

        if signatures.contains(where: { $0.kind == .overloadRecoveryOscillation }) {
            results.append(candidate(
                id: "structure-recovery-cadence",
                label: "Recovery-oriented cadence",
                detail: "Quiet stretches have been alternating with dense activity.",
                confidence: 0.57
            ))
        }

        if arcs.contains(where: { $0.arcType == .travelPlanning }) {
            results.append(candidate(
                id: "structure-travel-prep",
                label: "Travel-preparation phase",
                detail: "Travel-related activity has been recurring locally.",
                confidence: 0.55
            ))
        }

        if let month = monthlyRollups.last,
           month.facts.directionalThemes.count >= 2 {
            let theme = month.facts.directionalThemes.prefix(2).joined(separator: " · ")
            results.append(candidate(
                id: "structure-monthly-direction",
                label: "Directional month",
                detail: "Recent months suggest: \(theme).",
                confidence: 0.52
            ))
        }

        if let expectations, expectations.confidence >= 0.55, !expectations.continuityExpectations.isEmpty {
            results.append(candidate(
                id: "structure-expected-continuity",
                label: "Recurring activity pattern",
                detail: expectations.continuityExpectations.first ?? "",
                confidence: expectations.confidence * 0.92
            ))
        }

        return NoxPatternConfidenceModel.gate(results) { $0.confidence }
    }

    private static func candidate(
        id: String,
        label: String,
        detail: String,
        confidence: Double
    ) -> NoxLifeStructureCandidate {
        NoxLifeStructureCandidate(
            id: id,
            label: label,
            detail: NoxEmotionalSafetyCopy.sanitize(detail),
            confidence: confidence,
            revisable: true
        )
    }
}
