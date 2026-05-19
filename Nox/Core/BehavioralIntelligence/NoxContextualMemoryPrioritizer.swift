import Foundation

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
        existingNotes: [String]
    ) -> Result {
        let weightMap = Dictionary(uniqueKeysWithValues: weights.map { ($0.threadId, $0.weight) })

        let sortedThreads = threads.sorted { lhs, rhs in
            let lw = weightMap[lhs.id] ?? lhs.continuityStrength
            let rw = weightMap[rhs.id] ?? rhs.continuityStrength
            if abs(lw - rw) > 0.02 { return lw > rw }
            return lhs.lastSeenAt > rhs.lastSeenAt
        }

        let sortedArcs = arcs.sorted { lhs, rhs in
            if lhs.evolution == .strengthening, rhs.evolution != .strengthening { return true }
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
