import Foundation

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
