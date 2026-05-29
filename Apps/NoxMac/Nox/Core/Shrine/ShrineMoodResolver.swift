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
import NoxShrineCore

/// Deterministic mood from existing Nox signals. No LLM, no memory writes.
struct ShrineMoodInputs: Equatable, Sendable {
    var presence: NoxPresenceState
    var idleSeconds: TimeInterval
    var isUserIdle: Bool
    var pauseState: NoxAmbientPauseState
    var capabilities: NoxCapabilityState
    var focusAnalysis: NoxFocusAnalysis?
    var soundsMuted: Bool
    var overloadSignalCount: Int
    var hasSystemContradiction: Bool
    var hasUrgentIntervention: Bool
    var recentDismissCount: Int
}

enum OrbyMoodResolver {
    static func resolve(_ input: ShrineMoodInputs) -> OrbyMood {
        if input.soundsMuted {
            return .muted
        }
        if input.pauseState.observationPaused || input.pauseState.quietMode != .none {
            return .passive
        }

        if input.capabilities.appAwarenessAvailable == false || input.presence == .limited {
            return .disconnected
        }

        if input.hasUrgentIntervention {
            return .alarmed
        }

        if input.overloadSignalCount >= 4 {
            return .overloaded
        }

        if input.hasSystemContradiction || input.overloadSignalCount >= 2 {
            return .concerned
        }

        if input.recentDismissCount >= 3 {
            return .annoyed
        }
        if input.recentDismissCount == 2 {
            return .skeptical
        }

        switch input.presence {
        case .resting:
            return .sleepy
        case .idle:
            if input.idleSeconds >= 300 || input.isUserIdle { return .sleepy }
            if input.idleSeconds >= 180 { return .tired }
            return .passive
        case .distracted:
            if let focus = input.focusAnalysis, focus.switchCount >= 4 {
                return .curious
            }
            return .concerned
        case .focused, .flow:
            if let focus = input.focusAnalysis {
                if focus.uninterruptedMs >= 25 * 60 * 1000,
                   focus.continuityScore >= 0.78 {
                    return .deepFocus
                }
                if focus.continuityScore >= 0.72,
                   focus.uninterruptedMs >= 8 * 60 * 1000 {
                    return .pleased
                }
            }
            return .focused
        case .active:
            if let focus = input.focusAnalysis {
                if focus.switchCount >= 3 { return .curious }
                if focus.switchCount >= 1, focus.continuityScore < 0.4 { return .thinking }
            }
            return .neutral
        case .quiet:
            return input.idleSeconds >= 120 ? .nightWatch : .passive
        case .limited:
            return .disconnected
        }
    }

    @MainActor
    static func inputs(from environment: AppEnvironment, soundsMuted: Bool, recentDismissCount: Int) -> ShrineMoodInputs {
        let intervention = environment.connectorSnapshot.intervention
        let urgent = intervention?.kind == .systemState
            && intervention?.systemContradictionType != nil
        let contradiction = intervention?.systemContradictionType != nil
        return ShrineMoodInputs(
            presence: environment.presence,
            idleSeconds: environment.idleSeconds,
            isUserIdle: environment.isUserIdle,
            pauseState: environment.preferences.pauseState,
            capabilities: environment.capabilities,
            focusAnalysis: environment.focusAnalysis,
            soundsMuted: soundsMuted,
            overloadSignalCount: environment.connectorSnapshot.overloadSignals.count,
            hasSystemContradiction: contradiction,
            hasUrgentIntervention: urgent,
            recentDismissCount: recentDismissCount
        )
    }
}

typealias ShrineMoodResolver = OrbyMoodResolver
