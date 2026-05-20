import Foundation
import Testing
import NoxCore
@testable import Nox

struct NoxSemanticEvaluationCadenceTests {
    @Test func evaluatesImmediatelyForFirstSnapshotAndSurfaceChanges() {
        var cadence = NoxSemanticEvaluationCadence(stableInterval: 15, idleInterval: 45)
        let start = Date(timeIntervalSince1970: 100)
        let initial = snapshot(bundleId: "com.apple.Safari", title: "Docs", at: start)
        let changed = snapshot(bundleId: "com.apple.Safari", title: "Editor", at: start.addingTimeInterval(1))

        let first = cadence.shouldEvaluate(snapshot: initial, now: start)
        let surfaceChange = cadence.shouldEvaluate(snapshot: changed, now: changed.capturedAt)

        #expect(first)
        #expect(surfaceChange)
    }

    @Test func throttlesStableActiveSnapshotsWithoutSuppressingForcedEvaluation() {
        var cadence = NoxSemanticEvaluationCadence(stableInterval: 15, idleInterval: 45)
        let start = Date(timeIntervalSince1970: 200)
        let initial = snapshot(bundleId: "com.apple.dt.Xcode", title: "Nox", at: start)
        let stable = snapshot(bundleId: "com.apple.dt.Xcode", title: "Nox", at: start.addingTimeInterval(5))

        let first = cadence.shouldEvaluate(snapshot: initial, now: start)
        let stableRepeat = cadence.shouldEvaluate(snapshot: stable, now: stable.capturedAt)
        let forced = cadence.shouldEvaluate(snapshot: stable, force: true, now: stable.capturedAt)

        #expect(first)
        #expect(!stableRepeat)
        #expect(forced)
    }

    @Test func stableSnapshotsResumeAfterCadenceInterval() {
        var cadence = NoxSemanticEvaluationCadence(stableInterval: 15, idleInterval: 45)
        let start = Date(timeIntervalSince1970: 300)
        let initial = snapshot(bundleId: "com.apple.Terminal", title: "Build", at: start)
        let later = snapshot(bundleId: "com.apple.Terminal", title: "Build", at: start.addingTimeInterval(16))

        let first = cadence.shouldEvaluate(snapshot: initial, now: start)
        let afterInterval = cadence.shouldEvaluate(snapshot: later, now: later.capturedAt)

        #expect(first)
        #expect(afterInterval)
    }

    @Test func idleSnapshotsUseLongerCadenceButStillReactToIdleTransition() {
        var cadence = NoxSemanticEvaluationCadence(stableInterval: 15, idleInterval: 45)
        let start = Date(timeIntervalSince1970: 400)
        let active = snapshot(bundleId: "com.apple.Safari", title: "Video", idle: false, at: start)
        let idle = snapshot(bundleId: "com.apple.Safari", title: "Video", idle: true, at: start.addingTimeInterval(5))
        let stillIdle = snapshot(bundleId: "com.apple.Safari", title: "Video", idle: true, at: start.addingTimeInterval(20))
        let idleLater = snapshot(bundleId: "com.apple.Safari", title: "Video", idle: true, at: start.addingTimeInterval(51))

        let first = cadence.shouldEvaluate(snapshot: active, now: active.capturedAt)
        let idleTransition = cadence.shouldEvaluate(snapshot: idle, now: idle.capturedAt)
        let idleRepeat = cadence.shouldEvaluate(snapshot: stillIdle, now: stillIdle.capturedAt)
        let idleAfterInterval = cadence.shouldEvaluate(snapshot: idleLater, now: idleLater.capturedAt)

        #expect(first)
        #expect(idleTransition)
        #expect(!idleRepeat)
        #expect(idleAfterInterval)
    }

    private func snapshot(
        bundleId: String,
        title: String?,
        idle: Bool = false,
        at date: Date
    ) -> NoxActivitySnapshot {
        NoxActivitySnapshot(
            appName: "App",
            bundleId: bundleId,
            windowTitle: title,
            documentURL: nil,
            processId: 42,
            idleSeconds: idle ? 300 : 0,
            isUserIdle: idle,
            capturedAt: date
        )
    }
}
