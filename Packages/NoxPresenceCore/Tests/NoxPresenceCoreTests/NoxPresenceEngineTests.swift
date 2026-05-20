import Foundation
import NoxCore
import NoxPresenceCore
import Testing

struct NoxPresenceEnginePackageTests {

    private static let fullCapabilities = NoxCapabilityState(
        accessibilityGranted: true,
        screenRecordingGranted: false,
        appAwarenessAvailable: true,
        windowAwarenessAvailable: true,
        interactionSignalsAvailable: false
    )

    private static let appOnlyCapabilities = NoxCapabilityState(
        accessibilityGranted: false,
        screenRecordingGranted: false,
        appAwarenessAvailable: true,
        windowAwarenessAvailable: false,
        interactionSignalsAvailable: false
    )

    private func context(
        capabilities: NoxCapabilityState = fullCapabilities,
        idle: Bool = false,
        idleSeconds: TimeInterval = 0,
        bundleId: String? = "com.apple.dt.Xcode",
        appName: String? = "Xcode",
        timeInApp: TimeInterval = 0,
        switches: Int = 0,
        signals: Bool = true,
        focus: NoxFocusAnalysis? = nil
    ) -> NoxPresenceContext {
        NoxPresenceContext(
            capabilities: capabilities,
            isUserIdle: idle,
            idleSeconds: idleSeconds,
            currentBundleId: bundleId,
            currentAppName: appName,
            currentWindowTitle: nil,
            timeInCurrentApp: timeInApp,
            recentSwitchCount: switches,
            hasEnoughSignals: signals,
            focusAnalysis: focus
        )
    }

    @Test func limitedWhenNoAppAwarenessWithoutSignals() {
        let engine = NoxPresenceEngine()
        let unavailable = NoxCapabilityState.unavailable
        #expect(engine.evaluate(context: context(capabilities: unavailable, signals: false)) == .limited)
    }

    @Test func activeWhenAppOnlyWithSustainedActivity() {
        let engine = NoxPresenceEngine()
        let result = engine.evaluate(
            context: context(
                capabilities: Self.appOnlyCapabilities,
                bundleId: "com.apple.dt.Xcode",
                timeInApp: 600,
                signals: true
            )
        )
        #expect(result == .active)
    }

    @Test func quietWhenAppOnlyWithLowEngagement() {
        let engine = NoxPresenceEngine()
        let result = engine.evaluate(
            context: context(
                capabilities: Self.appOnlyCapabilities,
                bundleId: "com.apple.dt.Xcode",
                timeInApp: 30,
                switches: 0,
                signals: true
            )
        )
        #expect(result == .quiet)
    }

    @Test func noDeepStatesWithoutWindowAwareness() {
        let engine = NoxPresenceEngine()
        let result = engine.evaluate(
            context: context(
                capabilities: Self.appOnlyCapabilities,
                bundleId: "com.apple.dt.Xcode",
                timeInApp: 3600,
                switches: 0,
                signals: true,
                focus: NoxFocusAnalysis(
                    kind: .deepWork,
                    uninterruptedMs: 3_000_000,
                    switchCount: 0,
                    continuityScore: 0.95
                )
            )
        )
        #expect(result == .active)
        #expect(result != .focused)
        #expect(result != .flow)
    }

    @Test func idleAfterTwoMinutes() {
        let engine = NoxPresenceEngine()
        #expect(engine.evaluate(context: context(idle: true, idleSeconds: 150)) == .idle)
    }

    @Test func distractedOnFragmentedFocus() {
        let engine = NoxPresenceEngine()
        let focus = NoxFocusAnalysis(kind: .fragmented, uninterruptedMs: 0, switchCount: 8, continuityScore: 0.2)
        #expect(engine.evaluate(context: context(focus: focus)) == .distracted)
    }

    @Test func flowOnDeepWorkAnalysis() {
        let engine = NoxPresenceEngine()
        let focus = NoxFocusAnalysis(kind: .deepWork, uninterruptedMs: 3_000_000, switchCount: 1, continuityScore: 0.9)
        #expect(engine.evaluate(context: context(timeInApp: 2000, focus: focus)) == .flow)
    }
}
