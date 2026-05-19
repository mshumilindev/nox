import Foundation

/// Single source of truth for what Nox can observe on this Mac.
nonisolated struct NoxCapabilityState: Equatable, Sendable {
    let accessibilityGranted: Bool
    let screenRecordingGranted: Bool
    let appAwarenessAvailable: Bool
    let windowAwarenessAvailable: Bool
    let interactionSignalsAvailable: Bool

    var awarenessTier: NoxAwarenessTier {
        if !appAwarenessAvailable { return .unavailable }
        if windowAwarenessAvailable { return .full }
        return .appOnly
    }

    var allowsDeepPresence: Bool {
        windowAwarenessAvailable
    }

    var allowsFocusStates: Bool {
        windowAwarenessAvailable
    }

    static let unavailable = NoxCapabilityState(
        accessibilityGranted: false,
        screenRecordingGranted: false,
        appAwarenessAvailable: false,
        windowAwarenessAvailable: false,
        interactionSignalsAvailable: false
    )

    func derivedPermissionState() -> NoxPermissionState {
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

nonisolated enum NoxAwarenessTier: String, Equatable, Sendable {
    case full
    case appOnly
    case unavailable

    var summaryLine: String {
        switch self {
        case .full: "Full local awareness"
        case .appOnly: "App-level awareness"
        case .unavailable: "Observation unavailable"
        }
    }

    var presenceCeiling: NoxPresenceState {
        switch self {
        case .full: .flow
        case .appOnly: .active
        case .unavailable: .limited
        }
    }
}
