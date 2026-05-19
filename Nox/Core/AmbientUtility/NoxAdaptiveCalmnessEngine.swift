import Foundation

nonisolated enum NoxAdaptiveCalmnessEngine {

    static func profile(
        receptiveness: NoxInterventionReceptiveness,
        decompression: NoxDecompressionState,
        behavioral: NoxBehavioralIntelligenceSnapshot,
        connectorSnapshot: NoxConnectorContinuitySnapshot
    ) -> NoxAdaptiveCalmnessProfile {
        var reflectionDensity = 1.0
        var resurfacing = 1.0
        var intervention = 1.0
        var notification = 1.0
        var depth = 1.0
        var preferSilence = false

        if receptiveness.fragmented {
            reflectionDensity = 0.55
            resurfacing = 0.35
            intervention = 0.4
            notification = 0.25
            depth = 0.5
        }

        if receptiveness.deepFocusStable {
            intervention = 0.3
            notification = 0.2
            resurfacing = 0.45
        }

        if decompression.inDecompression {
            preferSilence = true
            intervention = 0.25
            notification = 0.15
            resurfacing = 0.2
            reflectionDensity = 0.65
        } else if decompression.recoveryWindowOpen {
            resurfacing = 0.7
            notification = 0.45
        }

        if !connectorSnapshot.overloadSignals.isEmpty {
            intervention = min(intervention, 0.5)
            notification = min(notification, 0.35)
            resurfacing = min(resurfacing, 0.4)
        }

        if behavioral.orchestration.signals.contains(where: { $0.kind == .returnAfterAbsence }) {
            resurfacing = min(1, resurfacing + 0.15)
            depth = min(1, depth + 0.1)
        }

        if receptiveness.score < 0.4 {
            preferSilence = true
        }

        return NoxAdaptiveCalmnessProfile(
            reflectionDensity: reflectionDensity,
            resurfacingFrequency: resurfacing,
            interventionProbability: intervention,
            notificationProbability: notification,
            continuitySurfacingDepth: depth,
            preferSilence: preferSilence
        )
    }
}
