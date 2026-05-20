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

nonisolated enum NoxTemporalCoherenceEngine {

    static func tune(
        snapshot: NoxMemoryEvolutionSnapshot,
        calmnessAllowsResurfacing: Bool
    ) -> NoxMemoryEvolutionSnapshot {
        let sparse = snapshot.preferSparseSurfaces
            || snapshot.agingProfiles.filter { $0.band == .archival || $0.band == .fading }.count
                >= max(2, snapshot.agingProfiles.count / 2)

        var longTermNotes = snapshot.longTermResurfacingNotes
        if !calmnessAllowsResurfacing {
            longTermNotes = []
        } else if sparse {
            longTermNotes = Array(longTermNotes.prefix(1))
        }

        let coherenceLine: String?
        if let first = snapshot.longHorizonStructures.first {
            coherenceLine = first
        } else if snapshot.unresolvedSignals.count >= 2 {
            coherenceLine = "Several activity threads have stayed open across longer stretches of time."
        } else if snapshot.eraHints.count >= 2 {
            coherenceLine = "Longer periods overlap softly rather than switching all at once."
        } else {
            coherenceLine = nil
        }

        return NoxMemoryEvolutionSnapshot(
            agingProfiles: snapshot.agingProfiles,
            longHorizonStructures: Array(snapshot.longHorizonStructures.prefix(sparse ? 1 : 2)),
            identityInsights: Array(snapshot.identityInsights.prefix(sparse ? 1 : 2)),
            eraHints: Array(snapshot.eraHints.prefix(2)),
            unresolvedSignals: Array(snapshot.unresolvedSignals.prefix(2)),
            ecologyNotes: Array(snapshot.ecologyNotes.prefix(1)),
            temporalWeights: snapshot.temporalWeights,
            resilienceScores: snapshot.resilienceScores,
            longTermResurfacingNotes: longTermNotes,
            temporalCoherenceLine: coherenceLine,
            prioritizedThreadIds: snapshot.prioritizedThreadIds,
            prioritizedArcIds: snapshot.prioritizedArcIds,
            preferSparseSurfaces: sparse
        )
    }
}
