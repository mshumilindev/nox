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

nonisolated enum NoxContextualMemoryPrioritizer {

    struct Result: Equatable, Sendable {
        let threadIds: [String]
        let arcIds: [String]
        let resurfacingNotes: [String]
    }

    static func prioritize(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        weights: [NoxAdaptiveContinuityWeight],
        signatures: [NoxBehavioralSignature],
        lifeStructures: [NoxLifeStructureCandidate],
        drift: NoxBehavioralDriftInsight?,
        existingNotes: [String],
        temporalWeights: [String: Double] = [:]
    ) -> Result {
        let weightMap = Dictionary(uniqueKeysWithValues: weights.map { ($0.threadId, $0.weight) })

        let sortedThreads = threads.sorted { lhs, rhs in
            let lw = temporalWeights[lhs.id] ?? weightMap[lhs.id] ?? lhs.continuityStrength
            let rw = temporalWeights[rhs.id] ?? weightMap[rhs.id] ?? rhs.continuityStrength
            if abs(lw - rw) > 0.02 { return lw > rw }
            if lhs.totalResumptions != rhs.totalResumptions {
                return lhs.totalResumptions > rhs.totalResumptions
            }
            return lhs.lastSeenAt > rhs.lastSeenAt
        }

        let sortedArcs = arcs.sorted { lhs, rhs in
            let lw = temporalWeights[lhs.id] ?? lhs.strength
            let rw = temporalWeights[rhs.id] ?? rhs.strength
            if abs(lw - rw) > 0.02 { return lw > rw }
            if lhs.evolution == .strengthening, rhs.evolution != .strengthening { return true }
            if lhs.continuityState == .resurfaced, rhs.continuityState != .resurfaced { return true }
            if lhs.strength != rhs.strength { return lhs.strength > rhs.strength }
            return lhs.lastSeenAt > rhs.lastSeenAt
        }

        var notes = existingNotes
        if let drift, drift.confidence >= 0.55 {
            let line = "\(drift.label). \(drift.detail)"
            if !notes.contains(where: { $0.hasPrefix(drift.label) }) {
                notes.append(NoxEmotionalSafetyCopy.sanitize(line))
            }
        }
        for structure in lifeStructures.prefix(2) {
            let line = structure.label
            if !notes.contains(line) {
                notes.append(NoxEmotionalSafetyCopy.sanitize(structure.detail))
            }
        }
        for signature in signatures.prefix(2) where signature.confidence >= 0.62 {
            if !notes.contains(signature.label) {
                notes.append(NoxEmotionalSafetyCopy.sanitize(signature.detail))
            }
        }

        return Result(
            threadIds: sortedThreads.map(\.id),
            arcIds: sortedArcs.map(\.id),
            resurfacingNotes: Array(notes.prefix(5))
        )
    }
}
