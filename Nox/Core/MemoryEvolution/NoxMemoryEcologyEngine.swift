import Foundation

nonisolated enum NoxMemoryEcologyEngine {

    static func evolve(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        agingProfiles: [NoxMemoryAgingProfile],
        temporalWeights: inout [String: Double],
        storedCoupling: inout [String: Double]
    ) -> [String] {
        let profileMap = Dictionary(uniqueKeysWithValues: agingProfiles.map { ($0.subjectId, $0) })
        var notes: [String] = []

        let strongThreads = threads.filter { ($0.continuityStrength >= 0.55 || $0.recurrenceStrength >= 0.5) }
        let fading = threads.filter { $0.decayState == .fading || $0.decayState == .dormant }

        for strong in strongThreads.prefix(4) {
            let weight = temporalWeights[strong.id] ?? strong.continuityStrength
            temporalWeights[strong.id] = min(1, weight + 0.06)

            for faded in fading where faded.semanticType == strong.semanticType {
                temporalWeights[faded.id] = max(0.08, (temporalWeights[faded.id] ?? faded.continuityStrength) * 0.94)
            }
        }

        for arc in arcs where arc.evolution == .strengthening {
            temporalWeights[arc.id] = min(1, (temporalWeights[arc.id] ?? arc.strength) + 0.05)
            if let related = threads.max(by: { $0.continuityStrength < $1.continuityStrength }) {
                let boost = (storedCoupling[related.id] ?? 0) + 0.04
                storedCoupling[related.id] = min(1, boost)
            }
        }

        let restorative = threads.filter {
            profileMap[$0.id]?.band == .resurfacing && $0.totalResumptions >= 1
        }
        if restorative.count >= 2 {
            notes.append("Returning continuity has been quietly strengthening nearby structures.")
        }

        let suppressed = fading.filter { (temporalWeights[$0.id] ?? 0) < 0.25 }.count
        if suppressed >= 2, strongThreads.count >= 1 {
            notes.append("Newer continuity has been making room for older shapes to rest.")
        }

        return Array(notes.prefix(2))
    }
}
