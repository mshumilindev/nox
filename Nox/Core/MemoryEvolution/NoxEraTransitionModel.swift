import Foundation

nonisolated enum NoxEraTransitionModel {

    static func overlapFactor(
        previousResonance: Double,
        currentStrength: Double
    ) -> Double {
        min(1, previousResonance * 0.4 + currentStrength * 0.35)
    }

    static func fadeRate(daysSinceLastTouch: Double) -> Double {
        if daysSinceLastTouch < 14 { return 0.02 }
        if daysSinceLastTouch < 45 { return 0.06 }
        return 0.1
    }

    static func regainResonance(
        stored: Double,
        resurfaced: Bool,
        structuralWeight: Double
    ) -> Double {
        var value = stored
        if resurfaced { value += 0.12 * structuralWeight }
        return min(1, value)
    }
}
