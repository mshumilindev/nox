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

nonisolated enum NoxUtilityRefinementEngine {

    static func refine(
        snapshot: NoxAmbientUtilitySnapshot,
        calibration: NoxAmbientUtilityCalibration,
        experiential: [NoxExperientialPriority]
    ) -> NoxAmbientUtilitySnapshot {
        let restraint = calibration.globalRestraint

        var calmness = snapshot.calmness
        calmness = NoxAdaptiveCalmnessProfile(
            reflectionDensity: calmness.reflectionDensity * restraint,
            resurfacingFrequency: calibration.recoveryQuality.suppressResurfacing
                ? calmness.resurfacingFrequency * 0.35
                : calmness.resurfacingFrequency * restraint,
            interventionProbability: calmness.interventionProbability * restraint,
            notificationProbability: calmness.notificationProbability * restraint,
            continuitySurfacingDepth: calmness.continuitySurfacingDepth * restraint,
            preferSilence: calibration.preferSilence
        )

        let minNudgeConfidence = 0.56 + (calibration.notificationFatigue * 0.08)
        let nudges = snapshot.nudges.filter { $0.confidence >= minNudgeConfidence }.prefix(1).map { $0 }

        let minUnfinished = 0.52 + (calibration.interruptionCost * 0.1)
        let unfinished = snapshot.unfinishedThreads
            .filter { $0.persistenceScore >= minUnfinished }
            .prefix(2)
            .map { $0 }

        var notification = snapshot.notificationCandidate
        if calibration.preferSilence || calibration.notificationFatigue >= 0.7 {
            notification = nil
        }

        var intervention: NoxAmbientIntervention? = snapshot.refinedIntervention
        if calibration.preferSilence || calibration.interruptionCost >= 0.68 {
            intervention = nil
        } else if let current = intervention, calibration.interruptionCost >= 0.55,
                  current.kind == .fragmentedDayAck {
            intervention = nil
        }

        _ = experiential

        return NoxAmbientUtilitySnapshot(
            nudges: Array(nudges),
            primaryNudge: nudges.first,
            calmness: calmness,
            receptiveness: snapshot.receptiveness,
            decompression: snapshot.decompression,
            recoveryWindow: snapshot.recoveryWindow,
            unfinishedThreads: unfinished,
            structuralWeights: snapshot.structuralWeights,
            attentionInsight: snapshot.attentionInsight,
            preferSilence: calibration.preferSilence,
            notificationCandidate: notification,
            refinedIntervention: intervention,
            calibration: calibration
        )
    }
}
