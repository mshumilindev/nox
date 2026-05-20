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

nonisolated enum NoxNotificationCalibrationEngine {

    static func calibratedAllows(
        candidate: NoxAmbientNotificationCandidate,
        fatigue: Double,
        trustScore: Double,
        interruptionCost: Double,
        baseAllows: Bool,
        preferSilence: Bool
    ) -> Bool {
        guard baseAllows else { return false }
        if preferSilence { return false }

        let minConfidence = 0.58 + (fatigue * 0.12) + (interruptionCost * 0.08)
        if candidate.confidence < minConfidence { return false }

        if fatigue >= 0.72 { return false }
        if interruptionCost >= 0.78, candidate.kind != "fragmentation_quiet" { return false }
        if trustScore < 0.45, candidate.confidence < 0.68 { return false }

        return true
    }
}
