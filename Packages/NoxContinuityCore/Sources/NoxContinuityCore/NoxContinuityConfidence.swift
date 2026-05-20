import Foundation
import NoxSemanticCore
import NoxMemoryCore
import NoxContextCore
import NoxCore

nonisolated public enum NoxContinuityConfidence {
    public static let matchThreshold = 0.55
    public static let attachThreshold = 0.62
    public static let resurfaceThreshold = 0.72
    public static let createThreshold = 0.45

    public static func accumulate(current: Double, matchScore: Double, sessionCount: Int) -> Double {
        let blend = (current * 0.65) + (matchScore * 0.35)
        let sessionBoost = min(0.12, Double(sessionCount) * 0.02)
        return min(0.95, blend + sessionBoost)
    }

    public static func recurrenceStrength(
        sessionCount: Int,
        resumptionCount: Int,
        spanCount: Int,
        daysActive: Int
    ) -> Double {
        let sessionFactor = min(0.4, Double(sessionCount) * 0.06)
        let resumeFactor = min(0.25, Double(resumptionCount) * 0.05)
        let spanFactor = min(0.2, Double(spanCount) * 0.02)
        let dayFactor = min(0.15, Double(daysActive) * 0.03)
        return min(0.92, sessionFactor + resumeFactor + spanFactor + dayFactor)
    }

    public static func continuityStrength(
        confidence: Double,
        totalDurationMs: Int,
        recurrence: Double
    ) -> Double {
        let durationMinutes = Double(totalDurationMs) / 60_000.0
        let durationFactor = min(0.35, durationMinutes / 240.0 * 0.35)
        return min(0.95, confidence * 0.45 + recurrence * 0.35 + durationFactor)
    }
}
