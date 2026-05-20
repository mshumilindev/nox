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

struct NoxTimelinePresenterTests {

    @Test func humanReadableAppChangedText() {
        let event = NoxEvent(
            type: .appChanged,
            payload: .appChanged(
                AppChangedPayload(
                    appName: "Cursor",
                    bundleId: "com.todesktop.230313mzl4w4u92",
                    windowTitle: nil,
                    previousAppName: "Safari",
                    previousBundleId: "com.apple.Safari"
                )
            )
        )
        #expect(NoxTimelinePresenter.displayText(for: event) == "Safari → Cursor")
    }

    @Test func interactionEventLabels() {
        let event = NoxEvent(
            type: .typingBurst,
            payload: .interaction(InteractionPayload(kind: .typingBurst, intensity: 12))
        )
        #expect(NoxTimelinePresenter.displayText(for: event).isEmpty)
    }
}
