import Foundation

@MainActor
enum NoxAmbientUtilityCalibrationOrchestrator {

    static func calibrate(
        base: NoxAmbientUtilitySnapshot,
        trust: inout NoxAmbientTrustState,
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        behavioral: NoxBehavioralIntelligenceSnapshot,
        connectorSnapshot: NoxConnectorContinuitySnapshot,
        ambientState: NoxAmbientState,
        notificationsEnabled: Bool,
        at date: Date = Date()
    ) -> (snapshot: NoxAmbientUtilitySnapshot, calibration: NoxAmbientUtilityCalibration) {
        trust.continuityGravity = NoxContinuityGravityEvolutionEngine.evolve(
            threads: threads,
            arcs: arcs,
            stored: trust.continuityGravity,
            at: date
        )

        let experiential = NoxExperientialPriorityEngine.priorities(
            threads: threads,
            arcs: arcs,
            gravity: trust.continuityGravity,
            stats: stats,
            behavioral: behavioral,
            at: date
        )

        let recoveryQuality = NoxDecompressionMaturityEngine.evaluate(
            base: base.decompression,
            stats: stats,
            focus: focus,
            behavioral: behavioral,
            recovery: base.recoveryWindow
        )

        let interruptionCost = NoxInterruptionCostEngine.estimate(
            focus: focus,
            stats: stats,
            receptiveness: base.receptiveness,
            decompression: base.decompression,
            behavioral: behavioral,
            calmness: base.calmness
        )

        let fatigue = NoxNotificationFatigueModel.fatigue(
            trust: trust,
            interruptionCost: interruptionCost,
            recentKinds: ambientState.recentNotificationKinds,
            at: date
        )
        trust.notificationFatigue = fatigue

        let globalRestraint = NoxAmbientTrustModel.globalRestraint(
            trust: trust,
            fatigue: fatigue,
            interruptionCost: interruptionCost
        )

        let basePreferSilence = base.preferSilence
        let preferSilence = NoxSilenceRefinementEngine.preferSilence(
            basePreferSilence: basePreferSilence,
            recoveryQuality: recoveryQuality,
            interruptionCost: interruptionCost,
            receptiveness: base.receptiveness,
            calmness: base.calmness,
            globalRestraint: globalRestraint
        )

        let (prioritizedThreadIds, prioritizedArcIds) = NoxLongHorizonRelevanceEngine.prioritizedIds(
            threads: threads,
            arcs: arcs,
            gravity: trust.continuityGravity,
            experiential: experiential,
            calibration: NoxAmbientUtilityCalibration(
                trustScore: trust.trustScore,
                notificationFatigue: fatigue,
                interruptionCost: interruptionCost,
                globalRestraint: globalRestraint,
                preferSilence: preferSilence,
                recoveryQuality: recoveryQuality,
                prioritizedThreadIds: [],
                prioritizedArcIds: [],
                experientialPriorities: experiential
            )
        )

        let calibration = NoxAmbientUtilityCalibration(
            trustScore: trust.trustScore,
            notificationFatigue: fatigue,
            interruptionCost: interruptionCost,
            globalRestraint: globalRestraint,
            preferSilence: preferSilence,
            recoveryQuality: recoveryQuality,
            prioritizedThreadIds: prioritizedThreadIds,
            prioritizedArcIds: prioritizedArcIds,
            experientialPriorities: experiential
        )

        var refined = NoxUtilityRefinementEngine.refine(
            snapshot: base,
            calibration: calibration,
            experiential: experiential
        )

        var notificationDelivered = false
        var notificationSuppressed = base.notificationCandidate != nil && refined.notificationCandidate == nil

        if let candidate = refined.notificationCandidate {
            let coordinator = NoxNotificationCooldownCoordinator(ambientState: ambientState)
            let cooldownMultiplier = NoxNotificationFatigueModel.cooldownMultiplier(
                fatigue: fatigue,
                trustScore: trust.trustScore
            )
            let baseAllows = coordinator.allows(
                candidate: candidate,
                calmness: refined.calmness,
                receptiveness: refined.receptiveness,
                preferSilence: preferSilence,
                at: date
            ) && passesExtendedCooldown(
                ambientState: ambientState,
                multiplier: cooldownMultiplier,
                at: date
            )

            let calibratedAllows = NoxNotificationCalibrationEngine.calibratedAllows(
                candidate: candidate,
                fatigue: fatigue,
                trustScore: trust.trustScore,
                interruptionCost: interruptionCost,
                baseAllows: baseAllows,
                preferSilence: preferSilence
            )

            if !calibratedAllows {
                refined = NoxAmbientUtilitySnapshot(
                    nudges: refined.nudges,
                    primaryNudge: refined.primaryNudge,
                    calmness: refined.calmness,
                    receptiveness: refined.receptiveness,
                    decompression: refined.decompression,
                    recoveryWindow: refined.recoveryWindow,
                    unfinishedThreads: refined.unfinishedThreads,
                    structuralWeights: refined.structuralWeights,
                    attentionInsight: refined.attentionInsight,
                    preferSilence: refined.preferSilence,
                    notificationCandidate: nil,
                    refinedIntervention: refined.refinedIntervention,
                    calibration: calibration
                )
                notificationSuppressed = notificationsEnabled
            } else {
                notificationDelivered = notificationsEnabled
            }
        }

        let poorTiming = interruptionCost >= 0.75 && notificationDelivered
        NoxNotificationTrustTracker.recordRefresh(
            trust: &trust,
            notificationDelivered: notificationDelivered,
            notificationSuppressed: notificationSuppressed,
            preferSilence: preferSilence,
            interruptionCost: interruptionCost,
            poorTiming: poorTiming,
            at: date
        )

        return (refined, calibration)
    }

    private static func passesExtendedCooldown(
        ambientState: NoxAmbientState,
        multiplier: Double,
        at date: Date
    ) -> Bool {
        guard let last = ambientState.lastAmbientNotificationAt else { return true }
        let required = 4 * 3600 * multiplier
        return date.timeIntervalSince(last) >= required
    }
}
