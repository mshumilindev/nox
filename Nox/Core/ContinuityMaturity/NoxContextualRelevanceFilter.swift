import Foundation

nonisolated enum NoxContextualRelevanceFilter {

    static func isRelevant(
        reflectionId: String,
        gravity: Double,
        context: NoxContinuityMaturityContext
    ) -> Bool {
        if gravity < 0.4 { return false }

        if context.isFragmented {
            if reflectionId == "reflection-focus-rhythm",
               context.input.focusSummary == "deep focus blocks" || context.input.focusSummary == "sustained focus" {
                return gravity >= 0.68
            }
            if reflectionId == "reflection-behavioral-pattern",
               context.behavioral.signatures.contains(where: { $0.kind == .deepFocusStreak }) {
                return gravity >= 0.65
            }
        }

        if context.isDeepFocus {
            if reflectionId == "reflection-fragmentation" { return gravity >= 0.62 }
            if reflectionId == "reflection-behavioral-drift" { return gravity >= 0.58 }
        }

        if context.overloadElevated {
            if reflectionId == "reflection-context-switching" { return gravity >= 0.58 }
            if reflectionId == "reflection-creative-arc" { return gravity >= 0.6 }
        }

        if context.orchestration.signals.contains(where: { $0.kind == .highInterruptionSensitivity && $0.level >= 0.6 }) {
            if reflectionId == "reflection-weekly-horizon" { return gravity >= 0.55 }
        }

        return true
    }
}
