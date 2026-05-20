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

nonisolated enum NoxMemoryDecayModel {

    static func resurfacingMultiplier(
        band: NoxMemoryAgingBand,
        temporalDistance: Double
    ) -> Double {
        let base: Double
        switch band {
        case .recentlyActive: base = 1
        case .resurfacing: base = 0.72
        case .fading: base = 0.48
        case .dormant: base = 0.32
        case .archival: base = 0.12
        }
        return base.scaled(by: 1 - temporalDistance * 0.25)
    }

    static func structuralWeight(
        band: NoxMemoryAgingBand,
        continuityStrength: Double,
        temporalDistance: Double
    ) -> Double {
        let base: Double
        switch band {
        case .recentlyActive: base = continuityStrength
        case .resurfacing: base = continuityStrength * 0.92
        case .fading: base = continuityStrength * 0.72
        case .dormant: base = continuityStrength * 0.55
        case .archival: base = continuityStrength * 0.35
        }
        return min(1, max(0.05, base * (1 - temporalDistance * 0.35)))
    }

    static func band(
        thread: NoxContinuityThread,
        temporalDistance: Double,
        at date: Date = Date()
    ) -> NoxMemoryAgingBand {
        if thread.currentStatus == .resumed || thread.lastResumedAt != nil,
           date.timeIntervalSince(thread.lastSeenAt) < 48 * 3600 {
            return .resurfacing
        }
        switch thread.decayState {
        case .active: return .recentlyActive
        case .fading: return .fading
        case .dormant: return .dormant
        case .archived: return .archival
        }
    }

    static func band(arc: NoxSemanticArc, temporalDistance: Double) -> NoxMemoryAgingBand {
        if arc.continuityState == .resurfaced { return .resurfacing }
        switch arc.continuityState {
        case .active, .merging: return .recentlyActive
        case .fading: return .fading
        case .dormant: return .dormant
        case .resurfaced: return .resurfacing
        }
    }
}

private extension Double {
    nonisolated func scaled(by factor: Double) -> Double {
        min(1, max(0.05, self * factor))
    }
}
