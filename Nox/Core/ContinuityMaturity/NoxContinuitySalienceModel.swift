import Foundation

nonisolated enum NoxContinuitySalienceModel {

    static func salience(
        reflectionId: String,
        gravity: Double,
        input: NoxReflectionInput,
        arcs: [NoxSemanticArc]
    ) -> NoxContinuitySalience {
        if reflectionId == "reflection-resurfaced-arc" {
            if input.continuityResumptions >= 4 { return .unresolved }
            if input.continuityResumptions >= 2 { return .returning }
            return .quiet
        }
        if reflectionId == "reflection-behavioral-drift" {
            return gravity >= 0.62 ? .fragile : .quiet
        }
        if reflectionId == "reflection-fragmentation" {
            return input.fragmentedSessions >= 3 ? .fragile : .quiet
        }
        if reflectionId == "reflection-recurring-thread" {
            if input.recurringThreadTitles.count >= 2 { return .stable }
            return .returning
        }
        if reflectionId == "reflection-life-structure" {
            return .stable
        }
        if let arc = arcs.first(where: { $0.continuityState == .resurfaced }) {
            if arc.evolution == .decaying || arc.evolution == .fragmenting { return .fading }
        }
        if gravity >= 0.72 { return .heavy }
        if gravity <= 0.42 { return .quiet }
        return .stable
    }
}
