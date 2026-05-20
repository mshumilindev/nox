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

nonisolated enum NoxMemoryAgingEngine {

    static func profiles(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        at date: Date = Date()
    ) -> [NoxMemoryAgingProfile] {
        var results: [NoxMemoryAgingProfile] = []

        for thread in threads {
            let distance = NoxTemporalDistanceModel.distance(
                lastSeenAt: thread.lastSeenAt,
                firstSeenAt: thread.firstSeenAt,
                at: date
            )
            let band = NoxMemoryDecayModel.band(thread: thread, temporalDistance: distance, at: date)
            results.append(NoxMemoryAgingProfile(
                subjectId: thread.id,
                band: band,
                temporalDistance: distance,
                resurfacingMultiplier: NoxMemoryDecayModel.resurfacingMultiplier(band: band, temporalDistance: distance),
                structuralWeight: NoxMemoryDecayModel.structuralWeight(
                    band: band,
                    continuityStrength: thread.continuityStrength,
                    temporalDistance: distance
                )
            ))
        }

        for arc in arcs {
            let distance = min(1, 1 - arc.strength * 0.4)
            let band = NoxMemoryDecayModel.band(arc: arc, temporalDistance: distance)
            results.append(NoxMemoryAgingProfile(
                subjectId: arc.id,
                band: band,
                temporalDistance: distance,
                resurfacingMultiplier: NoxMemoryDecayModel.resurfacingMultiplier(band: band, temporalDistance: distance),
                structuralWeight: NoxMemoryDecayModel.structuralWeight(
                    band: band,
                    continuityStrength: arc.strength,
                    temporalDistance: distance
                )
            ))
        }

        return results
    }
}
