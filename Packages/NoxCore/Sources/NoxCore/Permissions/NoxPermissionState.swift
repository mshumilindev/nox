import Foundation

public nonisolated struct NoxPermissionState: Equatable {
    public var accessibilityGranted: Bool
    public var screenRecordingGranted: Bool
    public var canReadAppContext: Bool
    public var canReadWindowTitle: Bool
    public var mode: NoxPermissionMode
    public var capabilities: NoxCapabilityState

    public init(
        accessibilityGranted: Bool,
        screenRecordingGranted: Bool,
        canReadAppContext: Bool,
        canReadWindowTitle: Bool,
        mode: NoxPermissionMode,
        capabilities: NoxCapabilityState
    ) {
        self.accessibilityGranted = accessibilityGranted
        self.screenRecordingGranted = screenRecordingGranted
        self.canReadAppContext = canReadAppContext
        self.canReadWindowTitle = canReadWindowTitle
        self.mode = mode
        self.capabilities = capabilities
    }

    public static let limited = NoxCapabilityState.unavailable.derivedPermissionState()

    public var summaryLine: String {
        capabilities.awarenessTier.summaryLine
    }

    public var appAwarenessLabel: String {
        capabilities.appAwarenessAvailable ? "Active" : "Unavailable"
    }

    public var windowContextLabel: String {
        if capabilities.windowAwarenessAvailable { return "Available" }
        if capabilities.accessibilityGranted { return "Available" }
        return "Requires Accessibility"
    }
}

public nonisolated enum NoxPermissionMode: String, Equatable {
    case full
    case appOnly
    case limited
}
