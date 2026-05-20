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

nonisolated enum NoxNudgeSuppressionModel {

    private static let nudgeCooldown: TimeInterval = 4 * 3600

    static func shouldSuppress(
        nudge: NoxContextualNudge,
        calmness: NoxAdaptiveCalmnessProfile,
        receptiveness: NoxInterventionReceptiveness,
        preferSilence: Bool,
        lastNudgeAt: Date?,
        at date: Date = Date()
    ) -> Bool {
        if preferSilence { return true }
        if nudge.confidence < 0.54 { return true }
        if !receptiveness.allowsResurfacing, nudge.kind != .decompressionSilence { return true }

        if let last = lastNudgeAt, date.timeIntervalSince(last) < nudgeCooldown {
            return true
        }

        if nudge.kind == .recoveryWindow, !receptiveness.recoveryOpen {
            return true
        }

        if calmness.interventionProbability < 0.35,
           nudge.kind == .fragmentationLoop {
            return true
        }

        return false
    }
}
