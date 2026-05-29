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

nonisolated enum NoxTemporalWeightEvolutionEngine {

    static func evolve(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        agingProfiles: [NoxMemoryAgingProfile],
        gravity: [String: Double],
        resilience: [String: Double],
        stored: inout [String: Double],
        at date: Date = Date()
    ) -> [String: Double] {
        let profileMap = Dictionary(uniqueKeysWithValues: agingProfiles.map { ($0.subjectId, $0) })

        for thread in threads {
            var weight = stored[thread.id]
                ?? gravity[thread.id]
                ?? NoxContinuityImportanceModel.threadImportance(thread, at: date)

            let profile = profileMap[thread.id]
            weight += thread.recurrenceStrength * 0.1 * (profile?.resurfacingMultiplier ?? 1)
            weight += min(0.12, Double(thread.totalResumptions) * 0.035)
            weight += (resilience[thread.id] ?? 0) * 0.08

            let months = NoxTemporalDistanceModel.monthsSinceFirstSeen(thread.firstSeenAt, at: date)
            if months >= 2 { weight += 0.06 }
            if months >= 4 { weight += 0.04 }

            if let profile, profile.band == .archival || profile.band == .fading {
                weight *= 0.88
            }

            stored[thread.id] = min(1, max(0.08, weight))
        }

        for arc in arcs {
            var weight = stored[arc.id]
                ?? gravity[arc.id]
                ?? NoxContinuityImportanceModel.arcImportance(arc)

            if arc.continuityState == .resurfaced { weight += 0.1 }
            if arc.evolution == .strengthening { weight += 0.05 }
            if arc.evolution == .decaying || arc.evolution == .fragmenting { weight *= 0.86 }

            stored[arc.id] = min(1, max(0.08, weight))
        }

        return pruneWeak(stored)
    }

    private static func pruneWeak(_ map: [String: Double]) -> [String: Double] {
        map.filter { $0.value >= 0.2 }
    }
}
