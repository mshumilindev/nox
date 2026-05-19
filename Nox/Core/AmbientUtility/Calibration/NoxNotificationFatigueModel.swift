import Foundation

nonisolated enum NoxNotificationFatigueModel {

    static func fatigue(
        trust: NoxAmbientTrustState,
        interruptionCost: Double,
        recentKinds: [String],
        at date: Date = Date()
    ) -> Double {
        var fatigue = trust.notificationFatigue

        if trust.deliveredNotificationCount >= 3 {
            fatigue += 0.12
        }
        if interruptionCost >= 0.65 {
            fatigue += 0.15
        }
        if recentKinds.count >= 2,
           Set(recentKinds.prefix(3)).count == 1 {
            fatigue += 0.1
        }
        if trust.poorTimingEventCount >= 2 {
            fatigue += 0.18
        }
        if let last = trust.lastCalibrationAt,
           date.timeIntervalSince(last) < 3600,
           trust.deliveredNotificationCount > 0 {
            fatigue += 0.08
        }

        return min(1, max(0, fatigue))
    }

    static func cooldownMultiplier(fatigue: Double, trustScore: Double) -> Double {
        let base = 1 + (fatigue * 2.5)
        let trustFactor = 1 + ((0.85 - trustScore) * 1.5)
        return max(1, base * trustFactor)
    }
}
