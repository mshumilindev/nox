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

struct NoxAwarenessSnapshot: Equatable, Sendable {
    let level: NoxAwarenessLevel
    let scopeLabel: String
    let confidenceLine: String?
    let visibilityLine: String?
    let permissionLines: [String]
}

enum NoxAwarenessPresenter {

    static func snapshot(
        capabilities: NoxCapabilityState,
        memoryReadiness: NoxMemoryReadiness,
        pauseState: NoxAmbientPauseState,
        sensitivity: NoxSensitivityLevel
    ) -> NoxAwarenessSnapshot {
        let level = resolveLevel(
            capabilities: capabilities,
            memoryReadiness: memoryReadiness,
            pauseState: pauseState
        )

        return NoxAwarenessSnapshot(
            level: level,
            scopeLabel: scopeLabel(level: level, pauseState: pauseState),
            confidenceLine: confidenceLine(memoryReadiness: memoryReadiness, level: level),
            visibilityLine: NoxSemanticVisibilityPresenter.line(for: sensitivity),
            permissionLines: permissionLines(capabilities: capabilities)
        )
    }

    static func resolveLevel(
        capabilities: NoxCapabilityState,
        memoryReadiness: NoxMemoryReadiness,
        pauseState: NoxAmbientPauseState
    ) -> NoxAwarenessLevel {
        if pauseState.observationPaused || !capabilities.appAwarenessAvailable {
            return .minimal
        }
        if pauseState.semanticMemoryPaused || pauseState.quietMode == .lowAwareness {
            return capabilities.windowAwarenessAvailable ? .contextAwareness : .appAwareness
        }
        if capabilities.windowAwarenessAvailable,
           capabilities.interactionSignalsAvailable,
           memoryReadiness == .ready {
            return .fullSemantic
        }
        if capabilities.windowAwarenessAvailable {
            return .contextAwareness
        }
        return .appAwareness
    }

    private static func scopeLabel(level: NoxAwarenessLevel, pauseState: NoxAmbientPauseState) -> String {
        if pauseState.quietMode != .none {
            return "\(pauseState.quietMode.title) · \(level.scopeLabel)"
        }
        return level.scopeLabel
    }

    private static func confidenceLine(
        memoryReadiness: NoxMemoryReadiness,
        level: NoxAwarenessLevel
    ) -> String? {
        switch memoryReadiness {
        case .observing:
            return "Memory is still forming — explanations stay light."
        case .building:
            return level >= .contextAwareness
                ? "Patterns are forming across recent sessions."
                : nil
        case .ready:
            return nil
        }
    }

    private static func permissionLines(capabilities: NoxCapabilityState) -> [String] {
        var lines: [String] = []
        if capabilities.accessibilityGranted {
            lines.append("Accessibility allows window titles on this Mac.")
        } else {
            lines.append("Additional context available with Accessibility.")
        }
        if capabilities.screenRecordingGranted {
            lines.append("Screen recording is optional and unused for content capture.")
        }
        return lines
    }
}
