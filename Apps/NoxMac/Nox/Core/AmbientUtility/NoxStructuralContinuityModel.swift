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

/// Topology weights for recurring, unresolved, and stabilizing continuity structures.
nonisolated enum NoxStructuralContinuityModel {
    static func weights(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        stats: NoxMemoryDayStats,
        behavioral: NoxBehavioralIntelligenceSnapshot,
        at date: Date = Date()
    ) -> [NoxStructuralContinuityWeight] {
        NoxPriorityTopologyEngine.structuralWeights(
            threads: threads,
            arcs: arcs,
            stats: stats,
            behavioral: behavioral,
            at: date
        )
    }
}
