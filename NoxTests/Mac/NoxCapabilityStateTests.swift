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

struct NoxCapabilityStateTests {

    @Test func appOnlyTierMatchesPermissionMode() {
        let capabilities = NoxCapabilityState(
            accessibilityGranted: false,
            screenRecordingGranted: false,
            appAwarenessAvailable: true,
            windowAwarenessAvailable: false,
            interactionSignalsAvailable: false
        )
        #expect(capabilities.awarenessTier == .appOnly)
        #expect(capabilities.derivedPermissionState().mode == .appOnly)
    }

    @Test func matrixShowsLayeredStatuses() {
        let rows = NoxCapabilityMatrix.rows(
            capabilities: NoxCapabilityState(
                accessibilityGranted: false,
                screenRecordingGranted: false,
                appAwarenessAvailable: true,
                windowAwarenessAvailable: false,
                interactionSignalsAvailable: false
            ),
            memoryReadiness: .building,
            interactionPipelineActive: true
        )
        #expect(rows.contains { $0.feature == "Apps in use" && $0.status == "Active" })
        #expect(rows.contains {
            $0.feature == "Window context"
                && $0.status == "Limited — Accessibility can unlock titles"
        })
    }

    @Test func fullTierWhenAccessibilityGranted() {
        let capabilities = NoxCapabilityState(
            accessibilityGranted: true,
            screenRecordingGranted: false,
            appAwarenessAvailable: true,
            windowAwarenessAvailable: true,
            interactionSignalsAvailable: false
        )
        #expect(capabilities.awarenessTier == .full)
        #expect(capabilities.allowsDeepPresence)
    }
}
