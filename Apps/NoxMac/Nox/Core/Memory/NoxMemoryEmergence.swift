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

struct NoxMemoryEmergence: Equatable, Sendable {
    let continuitySeconds: TimeInterval
    let readiness: NoxMemoryReadiness
    let liveSignalCount: Int
    var continuityNote: String?
    var maturity: NoxMemoryMaturity = .transient
    var emergingObservations: [NoxEmergingMemoryObservation] = []

    var title: String {
        let copy = NoxEmergingMemoryEngine.primaryCopy(
            maturity: maturity,
            observations: emergingObservations,
            readiness: readiness
        )
        return copy.title
    }

    var detail: String {
        let copy = NoxEmergingMemoryEngine.primaryCopy(
            maturity: maturity,
            observations: emergingObservations,
            readiness: readiness
        )
        return copy.detail
    }

    var observationWindowLine: String? {
        if let continuityNote, !continuityNote.isEmpty {
            return humanizeContinuityNote(continuityNote)
        }
        return nil
    }

    var ambientDensity: Double {
        min(1.0, continuitySeconds / 900)
    }

    private func humanizeContinuityNote(_ note: String) -> String {
        if note.contains("interrupted by restart") {
            return "Picked up after a restart"
        }
        if note.contains("Resumed session") {
            return note.replacingOccurrences(of: "Resumed session", with: "Continued in")
        }
        return note
    }
}
