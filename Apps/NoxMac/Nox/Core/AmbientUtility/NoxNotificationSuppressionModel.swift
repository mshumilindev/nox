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

nonisolated enum NoxNotificationSuppressionModel {

    static func shouldSuppress(
        candidate: NoxAmbientNotificationCandidate,
        coordinator: NoxNotificationCooldownCoordinator,
        calmness: NoxAdaptiveCalmnessProfile,
        receptiveness: NoxInterventionReceptiveness,
        preferSilence: Bool,
        notificationsEnabled: Bool,
        at date: Date = Date()
    ) -> Bool {
        if !notificationsEnabled { return true }
        if preferSilence { return true }
        if !coordinator.allows(
            candidate: candidate,
            calmness: calmness,
            receptiveness: receptiveness,
            preferSilence: preferSilence,
            at: date
        ) {
            return true
        }
        return false
    }
}
