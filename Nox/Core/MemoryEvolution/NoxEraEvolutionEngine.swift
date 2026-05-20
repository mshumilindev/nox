import Foundation

nonisolated enum NoxEraEvolutionEngine {

    static func evolve(
        typedMemories: [NoxTypedMemoryEntity],
        stored: inout [String: Double],
        agingProfiles: [NoxMemoryAgingProfile],
        at date: Date = Date()
    ) -> [NoxEraEvolutionHint] {
        let eras = typedMemories.filter {
            $0.kind == .projectArc || $0.sourceHorizon == .era
        }

        var hints: [NoxEraEvolutionHint] = []
        let profileMap = Dictionary(uniqueKeysWithValues: agingProfiles.map { ($0.subjectId, $0) })

        for era in eras.prefix(5) {
            var resonance = stored[era.id] ?? era.confidence
            let touchGap = date.timeIntervalSince(era.updatedAt) / 86_400
            resonance -= NoxEraTransitionModel.fadeRate(daysSinceLastTouch: touchGap)

            let resurfaced = profileMap[era.id]?.band == .resurfacing
            let weight = profileMap[era.id]?.structuralWeight ?? 0.5
            resonance = NoxEraTransitionModel.regainResonance(
                stored: resonance,
                resurfaced: resurfaced,
                structuralWeight: weight
            )

            stored[era.id] = min(1, max(0.08, resonance))

            guard resonance >= 0.28 else { continue }
            let overlap = NoxEraTransitionModel.overlapFactor(
                previousResonance: stored[era.id] ?? resonance,
                currentStrength: era.confidence
            ) > 0.35

            let softLabel = era.title.isEmpty
                ? "A longer-running activity period"
                : era.title
            hints.append(NoxEraEvolutionHint(
                id: era.id,
                softLabel: softLabel,
                resonance: resonance,
                overlapping: overlap
            ))
        }

        return hints
            .sorted { $0.resonance > $1.resonance }
            .prefix(3)
            .map { $0 }
    }
}
