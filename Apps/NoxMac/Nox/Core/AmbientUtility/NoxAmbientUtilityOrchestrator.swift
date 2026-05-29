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

@MainActor
enum NoxAmbientUtilityOrchestrator {

    static func refresh(
        paused: Bool,
        preferences: NoxAmbientUtilityPreferences,
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        connectorSnapshot: NoxConnectorContinuitySnapshot,
        behavioralSnapshot: NoxBehavioralIntelligenceSnapshot,
        proposedIntervention: NoxAmbientIntervention?,
        lastNudgeAt: Date?,
        ambientState: NoxAmbientState,
        at date: Date = Date()
    ) -> NoxAmbientUtilitySnapshot {
        guard !paused else { return .empty }

        let (decompression, recovery) = NoxDecompressionEngine.evaluate(
            stats: stats,
            focus: focus,
            behavioral: behavioralSnapshot,
            connectorSnapshot: connectorSnapshot
        )
        let receptiveness = NoxInterventionReceptivenessModel.evaluate(
            focus: focus,
            stats: stats,
            behavioral: behavioralSnapshot,
            decompression: decompression
        )
        let calmness = NoxAdaptiveCalmnessEngine.profile(
            receptiveness: receptiveness,
            decompression: decompression,
            behavioral: behavioralSnapshot,
            connectorSnapshot: connectorSnapshot
        )
        let preferSilence = NoxAmbientSilenceEngine.shouldPreferSilence(
            receptiveness: receptiveness,
            decompression: decompression,
            calmness: calmness,
            behavioral: behavioralSnapshot
        )
        let structural = NoxStructuralContinuityModel.weights(
            threads: threads,
            arcs: arcs,
            stats: stats,
            behavioral: behavioralSnapshot,
            at: date
        )
        let unfinished = NoxUnfinishedThreadEngine.candidates(threads: threads, arcs: arcs, at: date)
        let attention = NoxAttentionBalanceEngine.insight(
            stats: stats,
            focus: focus,
            threads: threads,
            structural: structural
        )

        let rawNudges = NoxContinuityNudgeEngine.build(
            unfinished: unfinished,
            structural: structural,
            decompression: decompression,
            recovery: recovery,
            behavioral: behavioralSnapshot,
            receptiveness: receptiveness
        )
        let nudges = rawNudges.filter { nudge in
            !NoxNudgeSuppressionModel.shouldSuppress(
                nudge: nudge,
                calmness: calmness,
                receptiveness: receptiveness,
                preferSilence: preferSilence,
                lastNudgeAt: lastNudgeAt,
                at: date
            )
        }
        let primaryNudge = nudges.first

        let refinedIntervention = refineIntervention(
            proposedIntervention,
            calmness: calmness,
            receptiveness: receptiveness,
            preferSilence: preferSilence
        )

        let fragmentedReduction = preferSilence && receptiveness.fragmented
        var notificationCandidate = NoxNotificationRelevanceModel.candidate(
            unfinished: unfinished,
            behavioral: behavioralSnapshot,
            receptiveness: receptiveness,
            calmness: calmness,
            preferSilence: preferSilence,
            fragmentedReductionActive: fragmentedReduction
        )
        if let candidate = notificationCandidate,
           NoxNotificationSuppressionModel.shouldSuppress(
            candidate: candidate,
            coordinator: NoxNotificationCooldownCoordinator(ambientState: ambientState),
            calmness: calmness,
            receptiveness: receptiveness,
            preferSilence: preferSilence,
            notificationsEnabled: preferences.ambientNotificationsEnabled,
            at: date
           ) {
            notificationCandidate = nil
        }

        return NoxAmbientUtilitySnapshot(
            nudges: nudges,
            primaryNudge: primaryNudge,
            calmness: calmness,
            receptiveness: receptiveness,
            decompression: decompression,
            recoveryWindow: recovery,
            unfinishedThreads: unfinished,
            structuralWeights: structural,
            attentionInsight: attention,
            preferSilence: preferSilence,
            notificationCandidate: notificationCandidate,
            refinedIntervention: refinedIntervention,
            calibration: .neutral
        )
    }

    static func refineIntervention(
        _ proposed: NoxAmbientIntervention?,
        calmness: NoxAdaptiveCalmnessProfile,
        receptiveness: NoxInterventionReceptiveness,
        preferSilence: Bool
    ) -> NoxAmbientIntervention? {
        guard let proposed else { return nil }
        if preferSilence { return nil }
        if !receptiveness.allowsIntervention { return nil }
        if calmness.interventionProbability < 0.35 { return nil }
        if receptiveness.deepFocusStable, proposed.kind == .fragmentedDayAck { return nil }
        return proposed
    }
}
