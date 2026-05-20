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

enum NoxConnectorContinuityEnricher {

    static func enrichmentNotes(
        snapshot: NoxConnectorContinuitySnapshot,
        arcs: [NoxSemanticArc],
        threads: [NoxContinuityThread]
    ) -> [String] {
        guard !snapshot.cadencePatterns.isEmpty || !snapshot.generalizedSignals.isEmpty else {
            return []
        }
        var notes: [String] = []

        if snapshot.cadencePatterns.contains(where: { $0.id == "rhythm-overload-inactivity" }) {
            notes.append("Work and recovery have been alternating across recent days.")
        }

        if snapshot.cadencePatterns.contains(where: { $0.id == "rhythm-coordination-wednesday" }) {
            notes.append("Coordination-heavy Wednesdays may be recurring.")
        }

        if snapshot.generalizedSignals.contains(where: { $0.id == "calendar-travel-like" }) {
            notes.append("Travel planning has been showing up again.")
        }

        if snapshot.cadencePatterns.contains(where: { $0.id == "rhythm-deep-focus-era" }),
           arcs.contains(where: { $0.arcType == .development }) {
            notes.append("A late-night deep work era may be resurfacing.")
        }

        if threads.count >= 2,
           snapshot.pressureSignals.contains(where: { $0.kind == .communication }) {
            notes.append("Messages and meetings have been threading through recent work.")
        }

        return notes
            .prefix(3)
            .map { NoxEmotionalSafetyCopy.sanitize($0) }
    }
}
