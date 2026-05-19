import Foundation

struct NoxPermissionState: Equatable {
    var accessibilityGranted: Bool
    var screenRecordingGranted: Bool
    var canReadAppContext: Bool
    var canReadWindowTitle: Bool
    var mode: NoxPermissionMode
    var capabilities: NoxCapabilityState

    static let limited = NoxCapabilityState.unavailable.derivedPermissionState()

    var summaryLine: String {
        capabilities.awarenessTier.summaryLine
    }

    var appAwarenessLabel: String {
        capabilities.appAwarenessAvailable ? "Active" : "Unavailable"
    }

    var windowContextLabel: String {
        if capabilities.windowAwarenessAvailable { return "Available" }
        if capabilities.accessibilityGranted { return "Available" }
        return "Requires Accessibility"
    }
}

enum NoxPermissionMode: String, Equatable {
    case full
    case appOnly
    case limited
}
