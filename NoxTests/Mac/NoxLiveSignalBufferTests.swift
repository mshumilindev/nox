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

@MainActor
struct NoxLiveSignalBufferTests {

    @Test func removesStaleLimitedSignalWhenFullAwareness() {
        let buffer = NoxLiveSignalBuffer(capacity: 12)
        buffer.prepend(NoxLiveSignalPresenter.limitedMode())
        buffer.prepend(
            NoxLiveSignal(
                id: "app-1",
                timestamp: Date(),
                text: "Xcode active",
                kind: .app
            )
        )

        let full = NoxCapabilityState(
            accessibilityGranted: true,
            screenRecordingGranted: false,
            appAwarenessAvailable: true,
            windowAwarenessAvailable: true,
            interactionSignalsAvailable: false
        )

        let visible = buffer.visibleSignals(capabilities: full)
        #expect(!visible.contains { $0.text == NoxLiveSignal.limitedObservationText })
        #expect(visible.contains { $0.text == "Xcode active" })
    }

    @Test func expiresTransientSignals() {
        let buffer = NoxLiveSignalBuffer(capacity: 12)
        let old = NoxLiveSignal(
            id: "old",
            timestamp: Date().addingTimeInterval(-200),
            text: "Observing local activity…",
            kind: .awareness,
            lifecycle: .transient(30)
        )
        buffer.prepend(old)
        let visible = buffer.visibleSignals(
            capabilities: NoxCapabilityState(
                accessibilityGranted: false,
                screenRecordingGranted: false,
                appAwarenessAvailable: true,
                windowAwarenessAvailable: false,
                interactionSignalsAvailable: false
            )
        )
        #expect(!visible.contains { $0.id == "old" })
    }
}
