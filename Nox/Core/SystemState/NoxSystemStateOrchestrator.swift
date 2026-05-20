import Foundation

@MainActor
enum NoxSystemStateOrchestrator {

    static func integrate(
        utility: NoxAmbientUtilitySnapshot,
        behavioralIntervention: NoxAmbientIntervention?,
        context: NoxSystemContradictionContext,
        preferences: NoxSystemStatePreferences,
        persistence: inout NoxSystemStatePersistence,
        provider: NoxSystemStateProviding? = nil,
        at date: Date = Date()
    ) -> (snapshot: NoxAmbientUtilitySnapshot, intervention: NoxAmbientIntervention?, trayHint: String?) {
        let stateProvider = provider ?? NoxSystemStateProvider()
        NoxCaffeinateController.shared.pruneIfExpired(at: date)

        let system = stateProvider.snapshot(
            noxCaffeinateActive: NoxCaffeinateController.shared.isActive(at: date),
            at: date
        )

        let candidates = NoxSystemContradictionEngine.evaluate(
            system: system,
            context: context,
            preferences: preferences,
            at: date
        )

        let contradiction = NoxSystemContradictionSuppressionModel.eligible(
            candidates,
            system: system,
            preferSilence: utility.preferSilence,
            interruptionCost: utility.calibration.interruptionCost,
            receptiveness: utility.receptiveness,
            persistence: persistence,
            at: date
        )

        guard let contradiction else {
            return (utility, utility.refinedIntervention ?? behavioralIntervention, nil)
        }

        guard shouldPreferSystemOverExisting(
            system: contradiction,
            existing: utility.refinedIntervention ?? behavioralIntervention
        ) else {
            return (utility, utility.refinedIntervention ?? behavioralIntervention, nil)
        }

        guard passesUtilityGates(utility: utility) else {
            return (utility, utility.refinedIntervention ?? behavioralIntervention, nil)
        }

        let intervention = NoxSystemContradictionPresenter.intervention(from: contradiction, at: date)
        NoxSystemContradictionSuppressionModel.recordShown(persistence: &persistence, at: date)

        let updated = NoxAmbientUtilitySnapshot(
            nudges: utility.nudges,
            primaryNudge: utility.primaryNudge,
            calmness: utility.calmness,
            receptiveness: utility.receptiveness,
            decompression: utility.decompression,
            recoveryWindow: utility.recoveryWindow,
            unfinishedThreads: utility.unfinishedThreads,
            structuralWeights: utility.structuralWeights,
            attentionInsight: utility.attentionInsight,
            preferSilence: utility.preferSilence,
            notificationCandidate: utility.notificationCandidate,
            refinedIntervention: intervention,
            calibration: utility.calibration
        )

        return (
            updated,
            intervention,
            NoxSystemContradictionPresenter.trayHint(for: intervention)
        )
    }

    private static func shouldPreferSystemOverExisting(
        system: NoxSystemContradiction,
        existing: NoxAmbientIntervention?
    ) -> Bool {
        guard let existing else { return true }
        if existing.kind == .systemState { return true }
        return system.confidence >= 0.66
    }

    private static func passesUtilityGates(utility: NoxAmbientUtilitySnapshot) -> Bool {
        if utility.preferSilence { return false }
        if !utility.receptiveness.allowsIntervention { return false }
        if utility.calmness.interventionProbability < 0.32 { return false }
        if utility.calibration.interruptionCost >= 0.72 { return false }
        return true
    }
}
