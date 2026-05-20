import Foundation

/// Single source of truth for what Nox can observe on this Mac.
public nonisolated struct NoxCapabilityState: Equatable, Sendable {
    public let accessibilityGranted: Bool
    public let screenRecordingGranted: Bool
    public let appAwarenessAvailable: Bool
    public let windowAwarenessAvailable: Bool
    public let interactionSignalsAvailable: Bool

    public var awarenessTier: NoxAwarenessTier {
        if !appAwarenessAvailable { return .unavailable }
        if windowAwarenessAvailable { return .full }
        return .appOnly
    }

    public var allowsDeepPresence: Bool {
        windowAwarenessAvailable
    }

    public var allowsFocusStates: Bool {
        windowAwarenessAvailable
    }

    public init(
        accessibilityGranted: Bool,
        screenRecordingGranted: Bool,
        appAwarenessAvailable: Bool,
        windowAwarenessAvailable: Bool,
        interactionSignalsAvailable: Bool
    ) {
        self.accessibilityGranted = accessibilityGranted
        self.screenRecordingGranted = screenRecordingGranted
        self.appAwarenessAvailable = appAwarenessAvailable
        self.windowAwarenessAvailable = windowAwarenessAvailable
        self.interactionSignalsAvailable = interactionSignalsAvailable
    }

    public static let unavailable = NoxCapabilityState(
        accessibilityGranted: false,
        screenRecordingGranted: false,
        appAwarenessAvailable: false,
        windowAwarenessAvailable: false,
        interactionSignalsAvailable: false
    )

    public func derivedPermissionState() -> NoxPermissionState {
        NoxPermissionState(
            accessibilityGranted: accessibilityGranted,
            screenRecordingGranted: screenRecordingGranted,
            canReadAppContext: appAwarenessAvailable,
            canReadWindowTitle: windowAwarenessAvailable,
            mode: permissionMode,
            capabilities: self
        )
    }

    private var permissionMode: NoxPermissionMode {
        switch awarenessTier {
        case .full: .full
        case .appOnly: .appOnly
        case .unavailable: .limited
        }
    }
}

public nonisolated enum NoxAwarenessTier: String, Equatable, Sendable {
    case full
    case appOnly
    case unavailable

    public var summaryLine: String {
        switch self {
        case .full: "Full local awareness"
        case .appOnly: "App-level awareness"
        case .unavailable: "Observation unavailable"
        }
    }

    public var presenceCeiling: NoxPresenceState {
        switch self {
        case .full: .flow
        case .appOnly: .active
        case .unavailable: .limited
        }
    }
}
