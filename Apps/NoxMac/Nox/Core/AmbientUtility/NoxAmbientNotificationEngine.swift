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
import UserNotifications

@MainActor
enum NoxAmbientNotificationEngine {

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        @unknown default:
            return false
        }
    }

    static func deliver(
        candidate: NoxAmbientNotificationCandidate,
        ambientState: inout NoxAmbientState,
        at date: Date = Date()
    ) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = candidate.title
        content.body = candidate.body
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: candidate.id,
            content: content,
            trigger: nil
        )

        try? await center.add(request)
        ambientState.lastAmbientNotificationAt = date
        var kinds = ambientState.recentNotificationKinds
        kinds.insert(candidate.kind, at: 0)
        if kinds.count > 8 { kinds = Array(kinds.prefix(8)) }
        ambientState.recentNotificationKinds = kinds
    }
}
