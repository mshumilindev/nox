import Foundation
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore

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
                feature: "Apps in use",
                status: capabilities.appAwarenessAvailable ? "Active" : "Limited",
                tone: capabilities.appAwarenessAvailable ? .active : .locked
            ),
            NoxCapabilityRow(
                id: "window-context",
                feature: "Window context",
                status: capabilities.windowAwarenessAvailable
                    ? "Available"
                    : "Limited — Accessibility can unlock titles",
                tone: capabilities.windowAwarenessAvailable ? .active : .pending
            ),
            NoxCapabilityRow(
                id: "interaction-semantics",
                feature: "Activity detail",
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
                feature: "Focus periods",
                status: capabilities.windowAwarenessAvailable ? "Available" : "Limited without window titles",
                tone: capabilities.windowAwarenessAvailable ? .active : .pending
            ),
            NoxCapabilityRow(
                id: "accessibility",
                feature: "Accessibility",
                status: capabilities.accessibilityGranted ? "On" : "Not enabled",
                tone: capabilities.accessibilityGranted ? .active : .pending
            ),
            NoxCapabilityRow(
                id: "screen-recording",
                feature: "Screen recording",
                status: capabilities.screenRecordingGranted ? "On" : "Optional",
                tone: capabilities.screenRecordingGranted ? .active : .pending
            )
        ]
    }

    private static func memoryStatus(_ readiness: NoxMemoryReadiness) -> String {
        switch readiness {
        case .observing: "Still forming"
        case .building: "Building"
        case .ready: "Available"
        }
    }

    private static func interactionSemanticsStatus(active: Bool, semanticsAvailable: Bool) -> String {
        if semanticsAvailable { return "Active" }
        if active { return "Still forming" }
        return "Limited"
    }

    private static func memoryTone(_ readiness: NoxMemoryReadiness) -> NoxCapabilityTone {
        switch readiness {
        case .observing: .pending
        case .building: .building
        case .ready: .active
        }
    }
}
