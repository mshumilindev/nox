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

nonisolated enum NoxContinuityPersistenceModel {

    static func persistenceScore(
        thread: NoxContinuityThread,
        arcs: [NoxSemanticArc],
        at date: Date = Date()
    ) -> Double {
        var score = thread.recurrenceStrength * 0.35
        score += min(0.25, Double(thread.totalResumptions) * 0.06)
        score += thread.continuityStrength * 0.2
        let days = max(0, date.timeIntervalSince(thread.firstSeenAt) / 86_400)
        if days >= 5 { score += 0.1 }
        if arcs.contains(where: { $0.label == thread.title && $0.continuityState == .resurfaced }) {
            score += 0.15
        }
        if thread.lastResumedAt != nil {
            let gap = date.timeIntervalSince(thread.lastResumedAt!)
            if gap < 72 * 3600 { score += 0.08 }
        }
        return min(1, score)
    }
}
