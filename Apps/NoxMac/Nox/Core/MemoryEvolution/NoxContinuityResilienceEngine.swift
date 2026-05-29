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

nonisolated enum NoxContinuityResilienceEngine {

    static func scores(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        focus: NoxFocusAnalysis?
    ) -> [String: Double] {
        var scores: [String: Double] = [:]

        for thread in threads {
            var score = thread.continuityStrength * 0.35
            score += min(0.25, Double(thread.totalResumptions) * 0.07)
            score += thread.recurrenceStrength * 0.2

            if thread.currentStatus == .resumed { score += 0.12 }
            if thread.decayState == .fading || thread.decayState == .dormant {
                score *= 0.75
            }
            if thread.interruptionPattern.contains("fragment") {
                score *= 0.88
            }

            scores[thread.id] = min(1, max(0, score))
        }

        for arc in arcs {
            var score = arc.strength * 0.45
            if arc.evolution == .strengthening { score += 0.15 }
            if arc.evolution == .stable { score += 0.08 }
            if arc.evolution == .fragmenting || arc.evolution == .decaying { score *= 0.7 }
            if arc.continuityState == .resurfaced { score += 0.1 }
            scores[arc.id] = min(1, max(0, score))
        }

        if let focus, focus.switchCount > 12 {
            for id in scores.keys {
                scores[id] = (scores[id] ?? 0) * 0.92
            }
        }

        return scores
    }
}
