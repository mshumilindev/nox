import Foundation

enum NoxPresenceState: String, Equatable, CaseIterable, Codable {
    case quiet
    case active
    case focused
    case distracted
    case idle
    case resting
    case flow
    case limited

    var title: String {
        switch self {
        case .quiet: "Quiet"
        case .active: "Active"
        case .focused: "Focused"
        case .distracted: "Distracted"
        case .idle: "Idle"
        case .resting: "Resting"
        case .flow: "Flow"
        case .limited: "Limited"
        }
    }

    func description(
        sessionSummary: String? = nil,
        capabilities: NoxCapabilityState? = nil
    ) -> String {
        if let sessionSummary, usesSessionSummary {
            return sessionSummary
        }

        return switch self {
        case .limited:
            capabilities?.appAwarenessAvailable == false
                ? "Waiting on permissions."
                : "Settling in."
        case .quiet:
            "Quiet on this Mac."
        case .active:
            "Active on this Mac."
        case .focused:
            "Current context has been steady."
        case .flow:
            "Deep focus with little switching."
        case .distracted:
            "Frequent switching in a short window."
        case .idle:
            "Idle for a few minutes."
        case .resting:
            "Resting for a while."
        }
    }

    private var usesSessionSummary: Bool {
        switch self {
        case .active, .focused, .flow: true
        default: false
        }
    }

    var symbolName: String {
        switch self {
        case .quiet: "moon.stars"
        case .active: "waveform.path"
        case .focused: "scope"
        case .distracted: "arrow.triangle.branch"
        case .idle: "pause.circle"
        case .resting: "moon.zzz"
        case .flow: "wind"
        case .limited: "lock.shield"
        }
    }

    var presenceLine: String {
        switch self {
        case .limited: "Limited"
        case .quiet: "Quiet"
        case .active: "Active"
        case .focused: "Focused"
        case .distracted: "Scattered"
        case .idle: "Idle"
        case .resting: "Resting"
        case .flow: "In flow"
        }
    }

    var shouldPulse: Bool {
        switch self {
        case .active, .focused, .flow: true
        default: false
        }
    }

    var shouldBreathe: Bool {
        switch self {
        case .active, .focused, .flow, .quiet: true
        default: false
        }
    }

    var accessibilityHint: String {
        "Local presence state: \(title)."
    }
}
