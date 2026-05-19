import Foundation

nonisolated enum NoxContinuityGravityEngine {

    static func reflectionGravity(
        reflectionId: String,
        input: NoxReflectionInput,
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        behavioral: NoxBehavioralIntelligenceSnapshot,
        at date: Date = Date()
    ) -> Double {
        let threadPeak = threads.map { NoxContinuityImportanceModel.threadImportance($0, at: date) }.max() ?? 0
        let arcPeak = arcs.map(NoxContinuityImportanceModel.arcImportance).max() ?? 0
        let base = (threadPeak * 0.45) + (arcPeak * 0.35)

        switch reflectionId {
        case "reflection-resurfaced-arc":
            var g = base + 0.18
            if input.continuityResumptions >= 3 { g += 0.12 }
            if input.resurfacedArcLabels.isEmpty { g -= 0.1 }
            return min(1, g)
        case "reflection-recurring-thread":
            return min(1, base + 0.14 + Double(input.recurringThreadTitles.count) * 0.04)
        case "reflection-behavioral-pattern":
            let sig = behavioral.signatures.first?.confidence ?? 0
            return min(1, 0.35 + sig * 0.45)
        case "reflection-behavioral-drift":
            return min(1, (behavioral.drift?.confidence ?? 0.5) * 0.75)
        case "reflection-life-structure":
            return min(1, 0.42 + (behavioral.lifeStructures.first?.confidence ?? 0) * 0.4)
        case "reflection-context-switching":
            return min(1, 0.48 + Double(input.semanticThemes.count) * 0.03)
        case "reflection-creative-arc":
            return min(1, arcPeak + 0.1)
        case "reflection-fragmentation":
            var g = 0.38 + Double(input.fragmentedSessions) * 0.06
            if input.focusSummary == "fragmented attention" { g += 0.1 }
            return min(1, g)
        case "reflection-weekly-horizon":
            return input.weeklyHorizonSnippet == nil ? 0.32 : 0.5
        case "reflection-focus-rhythm":
            return 0.34
        default:
            return min(1, base)
        }
    }
}
