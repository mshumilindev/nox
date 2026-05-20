import Foundation
import Testing
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
@testable import Nox

struct NoxTrustAndAwarenessTests {

    @Test func emotionalSafetyBlocksManipulativeCopy() {
        #expect(!NoxEmotionalSafetyCopy.isAllowed("You were productive yesterday!"))
        #expect(NoxEmotionalSafetyCopy.sanitize("Stay focused on your goals") != "Stay focused on your goals")
    }

    @Test func awarenessLevelRespectsPause() {
        let caps = NoxCapabilityState(
            accessibilityGranted: true,
            screenRecordingGranted: false,
            appAwarenessAvailable: true,
            windowAwarenessAvailable: true,
            interactionSignalsAvailable: true
        )
        var pause = NoxAmbientPauseState.active
        pause.observationPaused = true
        let level = NoxAwarenessPresenter.resolveLevel(
            capabilities: caps,
            memoryReadiness: .ready,
            pauseState: pause
        )
        #expect(level == .minimal)
    }

    @Test func quietModePausesSemanticIngest() {
        var pause = NoxAmbientPauseState.active
        NoxQuietModeEngine.apply(.privateSession, to: &pause)
        #expect(!NoxQuietModeEngine.shouldIngestSemanticMemory(pause))
    }
}
