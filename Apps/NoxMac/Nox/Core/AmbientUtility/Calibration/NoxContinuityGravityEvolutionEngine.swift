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

nonisolated enum NoxContinuityGravityEvolutionEngine {

    static func evolve(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        stored: [String: Double],
        at date: Date = Date()
    ) -> [String: Double] {
        var evolved = stored

        for thread in threads {
            let base = NoxContinuityImportanceModel.threadImportance(thread, at: date)
            var gravity = stored[thread.id] ?? base

            if thread.decayState == .fading {
                gravity = min(gravity, base + 0.05)
                gravity *= 0.82
            } else {
                gravity += thread.recurrenceStrength * 0.12
                gravity += min(0.15, Double(thread.totalResumptions) * 0.04)

                if thread.currentStatus == .resumed {
                    gravity += 0.06
                }

                let days = max(0, date.timeIntervalSince(thread.firstSeenAt) / 86_400)
                if days >= 14 { gravity += 0.08 }
                if days >= 30 { gravity += 0.05 }

                if thread.totalResumptions >= 2, thread.decayState != .active {
                    gravity += 0.07
                }
            }

            let blend = thread.decayState == .fading ? 0.18 : 0.08
            evolved[thread.id] = min(1, max(0.08, gravity * (1 - blend) + base * blend))
        }

        for arc in arcs {
            let base = NoxContinuityImportanceModel.arcImportance(arc)
            var gravity = stored[arc.id] ?? base

            if arc.continuityState == .resurfaced { gravity += 0.1 }
            if arc.evolution == .strengthening { gravity += 0.06 }
            if arc.evolution == .decaying || arc.evolution == .fragmenting {
                gravity *= 0.85
            }

            evolved[arc.id] = min(1, max(0.08, gravity * 0.9 + base * 0.1))
        }

        return pruneWeakEntries(evolved)
    }

    private static func pruneWeakEntries(_ map: [String: Double]) -> [String: Double] {
        map.filter { $0.value >= 0.22 }
    }
}
