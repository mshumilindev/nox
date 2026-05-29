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

enum NoxQuietModeEngine {

    static func apply(_ mode: NoxQuietMode, to state: inout NoxAmbientPauseState) {
        state.quietMode = mode
        switch mode {
        case .none:
            break
        case .quietEvening:
            state.continuityPaused = false
            state.semanticMemoryPaused = false
        case .privateSession:
            state.semanticMemoryPaused = true
            state.continuityPaused = true
        case .lowAwareness:
            state.observationPaused = false
            state.semanticMemoryPaused = true
        case .pauseContinuity:
            state.continuityPaused = true
        }
    }

    static func shouldIngestTimeline(_ state: NoxAmbientPauseState) -> Bool {
        !state.observationPaused
    }

    static func shouldIngestSemanticMemory(_ state: NoxAmbientPauseState) -> Bool {
        !state.semanticMemoryPaused && !state.observationPaused
    }

    static func shouldObserveContinuity(_ state: NoxAmbientPauseState) -> Bool {
        !state.continuityPaused && !state.semanticMemoryPaused && !state.observationPaused
    }

    static func shouldResurface(_ state: NoxAmbientPauseState) -> Bool {
        state.quietMode != .quietEvening && !state.continuityPaused
    }

    static func presenceCeiling(_ state: NoxAmbientPauseState, base: NoxPresenceState) -> NoxPresenceState {
        if state.observationPaused { return .quiet }
        if state.quietMode == .quietEvening, base == .flow { return .focused }
        return base
    }
}
