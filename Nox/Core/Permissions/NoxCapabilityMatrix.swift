import Foundation

enum NoxCapabilityTone: Equatable, Sendable {
    case active
    case building
    case pending
    case locked
}

struct NoxCapabilityRow: Identifiable, Equatable, Sendable {
    let id: String
    let feature: String
    let status: String
    let tone: NoxCapabilityTone
}

enum NoxCapabilityMatrix {
    static func rows(
        capabilities: NoxCapabilityState,
        memoryReadiness: NoxMemoryReadiness,
        interactionPipelineActive: Bool
    ) -> [NoxCapabilityRow] {
        [
            NoxCapabilityRow(
                id: "app-awareness",
                feature: "App context",
                status: capabilities.appAwarenessAvailable ? "Active" : "Limited context",
                tone: capabilities.appAwarenessAvailable ? .active : .locked
            ),
            NoxCapabilityRow(
                id: "window-context",
                feature: "Window context",
                status: capabilities.windowAwarenessAvailable
                    ? "Available"
                    : "Additional context available",
                tone: capabilities.windowAwarenessAvailable ? .active : .pending
            ),
            NoxCapabilityRow(
                id: "interaction-semantics",
                feature: "Context awareness",
                status: interactionSemanticsStatus(
                    active: interactionPipelineActive,
                    semanticsAvailable: capabilities.interactionSignalsAvailable
                ),
                tone: interactionPipelineActive ? .active : .pending
            ),
            NoxCapabilityRow(
                id: "memory",
                feature: "Recent memory",
                status: memoryStatus(memoryReadiness),
                tone: memoryTone(memoryReadiness)
            ),
            NoxCapabilityRow(
                id: "focus-detection",
                feature: "Focus continuity",
                status: capabilities.windowAwarenessAvailable ? "Available" : "Limited context",
                tone: capabilities.windowAwarenessAvailable ? .active : .pending
            ),
            NoxCapabilityRow(
                id: "accessibility",
                feature: "Accessibility",
                status: capabilities.accessibilityGranted ? "Allowed" : "Not yet allowed",
                tone: capabilities.accessibilityGranted ? .active : .pending
            ),
            NoxCapabilityRow(
                id: "screen-recording",
                feature: "Screen recording",
                status: capabilities.screenRecordingGranted ? "Allowed" : "Optional",
                tone: capabilities.screenRecordingGranted ? .active : .pending
            )
        ]
    }

    private static func memoryStatus(_ readiness: NoxMemoryReadiness) -> String {
        switch readiness {
        case .observing: "Emerging"
        case .building: "Emerging"
        case .ready: "Available"
        }
    }

    private static func interactionSemanticsStatus(active: Bool, semanticsAvailable: Bool) -> String {
        if semanticsAvailable { return "Active" }
        if active { return "Emerging" }
        return "Limited context"
    }

    private static func memoryTone(_ readiness: NoxMemoryReadiness) -> NoxCapabilityTone {
        switch readiness {
        case .observing: .pending
        case .building: .building
        case .ready: .active
        }
    }
}
