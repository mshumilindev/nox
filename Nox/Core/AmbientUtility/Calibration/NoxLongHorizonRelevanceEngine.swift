import Foundation

nonisolated enum NoxLongHorizonRelevanceEngine {

    static func prioritizedIds(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        gravity: [String: Double],
        experiential: [NoxExperientialPriority],
        calibration: NoxAmbientUtilityCalibration
    ) -> (threadIds: [String], arcIds: [String]) {
        guard !calibration.preferSilence else {
            return ([], [])
        }

        let expMap = Dictionary(uniqueKeysWithValues: experiential.map { ($0.subjectId, $0.significance) })

        let threadIds = threads
            .map { thread -> (String, Double) in
                let g = gravity[thread.id] ?? 0
                let e = expMap[thread.id] ?? 0
                return (thread.id, (g * 0.55) + (e * 0.45))
            }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map(\.0)

        let arcIds = arcs
            .map { arc -> (String, Double) in
                let g = gravity[arc.id] ?? 0
                let e = expMap[arc.id] ?? 0
                return (arc.id, (g * 0.55) + (e * 0.45))
            }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map(\.0)

        return (Array(threadIds), Array(arcIds))
    }

    static func resurfacingDepthMultiplier(calibration: NoxAmbientUtilityCalibration) -> Double {
        if calibration.preferSilence { return 0.2 }
        if calibration.recoveryQuality.suppressResurfacing { return 0.35 }
        return calibration.globalRestraint
    }
}
