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

nonisolated enum NoxTemporalDistanceModel {

    static func distance(
        lastSeenAt: Date,
        firstSeenAt: Date,
        at date: Date = Date()
    ) -> Double {
        let gapDays = max(0, date.timeIntervalSince(lastSeenAt) / 86_400)
        let spanDays = max(1, date.timeIntervalSince(firstSeenAt) / 86_400)
        let recency = min(1, gapDays / 45)
        let longevity = min(0.35, spanDays / 120)
        return min(1, max(0, recency * 0.85 - longevity * 0.15))
    }

    static func monthsSinceFirstSeen(_ firstSeenAt: Date, at date: Date = Date()) -> Double {
        max(0, date.timeIntervalSince(firstSeenAt) / (30 * 86_400))
    }
}
