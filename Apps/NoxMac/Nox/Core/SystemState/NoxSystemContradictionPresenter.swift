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

nonisolated enum NoxSystemContradictionPresenter {

    static let explainabilityDetail =
        "Based on local activity, current focus state, and recent session continuity."

    static let assuranceLine = "Nothing was changed automatically."

    static func intervention(
        from contradiction: NoxSystemContradiction,
        at date: Date = Date()
    ) -> NoxAmbientIntervention {
        NoxAmbientIntervention(
            id: contradiction.id,
            label: contradiction.label,
            detail: contradiction.detail,
            kind: .systemState,
            observedAt: date,
            systemContradictionType: contradiction.type,
            explainabilityDetail: contradiction.explainabilityDetail,
            assuranceLine: assuranceLine,
            actions: contradiction.actions
        )
    }

    static func trayHint(for intervention: NoxAmbientIntervention?) -> String? {
        guard let intervention, intervention.kind == .systemState else { return nil }
        guard intervention.systemContradictionType != nil else { return nil }
        return intervention.label
    }
}
