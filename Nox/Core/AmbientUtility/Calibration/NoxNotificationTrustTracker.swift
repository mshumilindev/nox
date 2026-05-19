import Foundation

nonisolated enum NoxNotificationTrustTracker {

    static func recordRefresh(
        trust: inout NoxAmbientTrustState,
        notificationDelivered: Bool,
        notificationSuppressed: Bool,
        preferSilence: Bool,
        interruptionCost: Double,
        poorTiming: Bool,
        at date: Date = Date()
    ) {
        if notificationDelivered {
            trust.deliveredNotificationCount += 1
            trust.notificationFatigue = min(1, trust.notificationFatigue + 0.08)
        }
        if notificationSuppressed {
            trust.suppressedUtilityCount += 1
            trust.notificationFatigue = max(0, trust.notificationFatigue - 0.02)
        }
        if poorTiming || (notificationDelivered && interruptionCost >= 0.72) {
            trust.poorTimingEventCount += 1
            trust.notificationFatigue = min(1, trust.notificationFatigue + 0.12)
            trust.trustScore = max(0.35, trust.trustScore - 0.04)
        }
        if preferSilence {
            trust.suppressedUtilityCount += 1
        }

        let deliveryRatio = deliveryRatioScore(trust)
        if deliveryRatio > 0.5, trust.poorTimingEventCount >= 2 {
            trust.trustScore = max(0.35, trust.trustScore - 0.06)
        } else if trust.suppressedUtilityCount > trust.deliveredNotificationCount + 3 {
            trust.trustScore = min(0.92, trust.trustScore + 0.02)
        }

        trust.trustScore = min(0.92, max(0.35, trust.trustScore))
        trust.notificationFatigue = min(1, max(0, trust.notificationFatigue))
        trust.lastCalibrationAt = date
    }

    private static func deliveryRatioScore(_ trust: NoxAmbientTrustState) -> Double {
        let total = trust.deliveredNotificationCount + trust.suppressedUtilityCount
        guard total > 0 else { return 0 }
        return Double(trust.deliveredNotificationCount) / Double(total)
    }
}
