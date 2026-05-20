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

nonisolated enum NoxLongHorizonContinuityEngine {

    static func structures(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        temporalWeights: [String: Double],
        at date: Date = Date()
    ) -> [String] {
        var lines: [String] = []

        let longThreads = threads.filter {
            NoxTemporalDistanceModel.monthsSinceFirstSeen($0.firstSeenAt, at: date) >= 1.5
                && ($0.recurrenceStrength >= 0.35 || $0.totalResumptions >= 2)
        }
        if let thread = longThreads.max(by: { temporalWeights[$0.id, default: 0] < temporalWeights[$1.id, default: 0] }) {
            let months = Int(NoxTemporalDistanceModel.monthsSinceFirstSeen(thread.firstSeenAt, at: date))
            if months >= 2 {
                let name = displayName(thread.title)
                lines.append("A \(name) shape has been returning across several months.")
            }
        }

        let recurringArcs = arcs.filter {
            $0.strength >= 0.4
                && ($0.evolution == .stable || $0.evolution == .strengthening)
                && $0.continuityState != .dormant
        }
        if lines.isEmpty, let arc = recurringArcs.first {
            lines.append("\(arc.label) has held a quiet long-running place in your continuity.")
        }

        let cadenceLike = threads.filter { $0.recurrenceStrength >= 0.5 && $0.totalSessions >= 4 }
        if cadenceLike.count >= 2, lines.count < 2 {
            lines.append("A few recurring rhythms have been threading through longer stretches of time.")
        }

        return Array(lines.prefix(2))
    }

    private static func displayName(_ title: String) -> String {
        title.replacingOccurrences(of: " continuity", with: "").lowercased()
    }
}
