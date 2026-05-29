import Foundation
import Testing
import NoxCore
@testable import Nox

@Test func shrineMoodDefaultsToPassiveWhenQuiet() {
    let input = ShrineMoodInputs(
        presence: .quiet,
        idleSeconds: 0,
        isUserIdle: false,
        pauseState: .active,
        capabilities: NoxCapabilityState(
            accessibilityGranted: true,
            screenRecordingGranted: true,
            appAwarenessAvailable: true,
            windowAwarenessAvailable: true,
            interactionSignalsAvailable: true
        ),
        focusAnalysis: nil,
        soundsMuted: false,
        overloadSignalCount: 0,
        hasSystemContradiction: false,
        hasUrgentIntervention: false,
        recentDismissCount: 0
    )
    #expect(ShrineMoodResolver.resolve(input) == .passive)
}

@Test func shrineMoodFocusedForFlow() {
    let input = ShrineMoodInputs(
        presence: .flow,
        idleSeconds: 0,
        isUserIdle: false,
        pauseState: .active,
        capabilities: NoxCapabilityState(
            accessibilityGranted: true,
            screenRecordingGranted: true,
            appAwarenessAvailable: true,
            windowAwarenessAvailable: true,
            interactionSignalsAvailable: true
        ),
        focusAnalysis: NoxFocusAnalysis(
            kind: nil,
            uninterruptedMs: 60_000,
            switchCount: 0,
            continuityScore: 0.5
        ),
        soundsMuted: false,
        overloadSignalCount: 0,
        hasSystemContradiction: false,
        hasUrgentIntervention: false,
        recentDismissCount: 0
    )
    #expect(ShrineMoodResolver.resolve(input) == .focused)
}

@Test func shrineMoodDisconnectedWhenLimited() {
    let input = ShrineMoodInputs(
        presence: .limited,
        idleSeconds: 0,
        isUserIdle: false,
        pauseState: .active,
        capabilities: .unavailable,
        focusAnalysis: nil,
        soundsMuted: false,
        overloadSignalCount: 0,
        hasSystemContradiction: false,
        hasUrgentIntervention: false,
        recentDismissCount: 0
    )
    #expect(ShrineMoodResolver.resolve(input) == .disconnected)
}
