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

nonisolated enum NoxBehavioralIntelligenceEnricher {

    static func enrichmentNotes(snapshot: NoxBehavioralIntelligenceSnapshot) -> [String] {
        var notes: [String] = snapshot.enrichmentNotes
        if let drift = snapshot.drift {
            notes.append("\(drift.label) — \(drift.detail)")
        }
        for structure in snapshot.lifeStructures.prefix(2) {
            notes.append(structure.detail)
        }
        return notes
            .map { NoxEmotionalSafetyCopy.sanitize($0) }
            .filter { !$0.isEmpty }
            .uniqued()
            .prefix(4)
            .map { $0 }
    }
}
