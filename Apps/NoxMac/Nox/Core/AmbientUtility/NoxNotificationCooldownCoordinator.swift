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

nonisolated struct NoxNotificationCooldownCoordinator {

    private static let globalCooldown: TimeInterval = 4 * 3600
    private static let kindCooldown: TimeInterval = 12 * 3600

    let lastNotificationAt: Date?
    let recentKinds: [String]

    init(ambientState: NoxAmbientState) {
        lastNotificationAt = ambientState.lastAmbientNotificationAt
        recentKinds = ambientState.recentNotificationKinds
    }

    func allows(
        candidate: NoxAmbientNotificationCandidate,
        calmness: NoxAdaptiveCalmnessProfile,
        receptiveness: NoxInterventionReceptiveness,
        preferSilence: Bool,
        at date: Date = Date()
    ) -> Bool {
        if preferSilence { return false }
        if !receptiveness.allowsNotification { return false }
        if calmness.notificationProbability < 0.3 { return false }
        if candidate.confidence < 0.58 { return false }

        if let last = lastNotificationAt, date.timeIntervalSince(last) < Self.globalCooldown {
            return false
        }

        if recentKinds.filter({ $0 == candidate.kind }).count >= 1,
           let last = lastNotificationAt,
           date.timeIntervalSince(last) < Self.kindCooldown {
            return false
        }

        return true
    }

    func recordDelivery(kind: String, at date: Date) -> (lastAt: Date, kinds: [String]) {
        var kinds = recentKinds
        kinds.insert(kind, at: 0)
        if kinds.count > 8 { kinds = Array(kinds.prefix(8)) }
        return (date, kinds)
    }
}
