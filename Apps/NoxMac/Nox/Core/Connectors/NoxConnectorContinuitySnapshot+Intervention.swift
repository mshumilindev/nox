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

extension NoxConnectorContinuitySnapshot {
    func replacingIntervention(_ intervention: NoxAmbientIntervention?) -> NoxConnectorContinuitySnapshot {
        NoxConnectorContinuitySnapshot(
            generalizedSignals: generalizedSignals,
            pressureSignals: pressureSignals,
            cadencePatterns: cadencePatterns,
            transitions: transitions,
            overloadSignals: overloadSignals,
            enrichmentNotes: enrichmentNotes,
            explainability: explainability,
            intervention: intervention
        )
    }
}
