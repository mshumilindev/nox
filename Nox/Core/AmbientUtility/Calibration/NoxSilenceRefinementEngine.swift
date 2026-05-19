import Foundation

nonisolated enum NoxSilenceRefinementEngine {

    static func preferSilence(
        basePreferSilence: Bool,
        recoveryQuality: NoxRecoveryQualityModel,
        interruptionCost: Double,
        receptiveness: NoxInterventionReceptiveness,
        calmness: NoxAdaptiveCalmnessProfile,
        globalRestraint: Double
    ) -> Bool {
        if basePreferSilence { return true }
        if recoveryQuality.preferSilence { return true }
        if interruptionCost >= 0.7 { return true }
        if receptiveness.deepFocusStable && receptiveness.interruptionSensitive { return true }
        if recoveryQuality.kind == .passiveCollapse || recoveryQuality.kind == .fragmentedEscapism {
            return true
        }
        if calmness.preferSilence { return true }
        if globalRestraint < 0.42 { return true }
        if receptiveness.fragmented && receptiveness.score < 0.38 { return true }
        return false
    }
}
