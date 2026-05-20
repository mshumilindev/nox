import Foundation
import NoxCore

/// What the system can observe right now — honest capability reporting.
public struct NoxContextCapabilityProfile: Equatable, Sendable {
    let appOnly: Bool
    let windowAware: Bool
    let automationAware: Bool
    let mediaAware: Bool
    let screenAware: Bool
    let accessibilityGranted: Bool
    let screenRecordingGranted: Bool
    let interactionSignalsAvailable: Bool

    public static func from(_ capabilities: NoxCapabilityState) -> NoxContextCapabilityProfile {
        NoxContextCapabilityProfile(
            appOnly: capabilities.appAwarenessAvailable && !capabilities.windowAwarenessAvailable,
            windowAware: capabilities.windowAwarenessAvailable,
            automationAware: false,
            mediaAware: false,
            screenAware: capabilities.screenRecordingGranted,
            accessibilityGranted: capabilities.accessibilityGranted,
            screenRecordingGranted: capabilities.screenRecordingGranted,
            interactionSignalsAvailable: capabilities.interactionSignalsAvailable
        )
    }

    var highestLevel: NoxContextAcquisitionLevel {
        if screenAware { return .screenAware }
        if mediaAware { return .mediaAware }
        if automationAware { return .automationAware }
        if windowAware { return .windowAware }
        return .appOnly
    }
}

public enum NoxContextAcquisitionLevel: String, Codable, Sendable, CaseIterable {
    case appOnly
    case windowAware
    case automationAware
    case mediaAware
    case screenAware
}
