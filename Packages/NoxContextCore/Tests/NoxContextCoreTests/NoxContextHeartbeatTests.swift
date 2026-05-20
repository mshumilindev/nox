import Foundation
import NoxContextCore
import NoxCore
import Testing

@MainActor
struct NoxContextHeartbeatTests {

    @Test func throttlesUnchangedContextWithinMinimumInterval() {
        let heartbeat = NoxContextHeartbeat()
        let now = Date()
        let snapshot = makeSnapshot(at: now)
        let evidence = makeEvidence(for: snapshot)

        heartbeat.recordEvaluation(snapshot: snapshot, label: "Research", now: now)

        #expect(!heartbeat.shouldEvaluate(
            snapshot: snapshot,
            evidence: evidence,
            now: now.addingTimeInterval(0.5)
        ))
    }

    @Test func preservesExplicitContextShiftEvaluation() {
        let heartbeat = NoxContextHeartbeat()
        let now = Date()
        let snapshot = makeSnapshot(at: now)
        let evidence = makeEvidence(for: snapshot)

        heartbeat.recordEvaluation(snapshot: snapshot, label: "Research", now: now)
        heartbeat.markContextShift()

        #expect(heartbeat.shouldEvaluate(
            snapshot: snapshot,
            evidence: evidence,
            now: now.addingTimeInterval(0.5)
        ))
        #expect(heartbeat.shouldPublishLabel("Research", now: now.addingTimeInterval(0.5)))
    }

    @Test func suppressesRepeatedLabelWithoutSuppressingNewLabelAfterCooldown() {
        let heartbeat = NoxContextHeartbeat()
        let now = Date()
        let snapshot = makeSnapshot(at: now)

        heartbeat.recordEvaluation(snapshot: snapshot, label: "Research", now: now)

        #expect(!heartbeat.shouldPublishLabel("Research", now: now.addingTimeInterval(4)))
        #expect(heartbeat.shouldPublishLabel("Writing", now: now.addingTimeInterval(4)))
    }

    private func makeSnapshot(at date: Date) -> NoxActivitySnapshot {
        NoxActivitySnapshot(
            appName: "Safari",
            bundleId: "com.apple.Safari",
            windowTitle: "GitHub pull request",
            documentURL: "https://github.com/example/repo/pull/1",
            processId: 42,
            idleSeconds: 0,
            isUserIdle: false,
            capturedAt: date
        )
    }

    private func makeEvidence(for snapshot: NoxActivitySnapshot) -> NoxContextEvidence {
        var pipeline = NoxContextAcquisitionPipeline()
        var metrics = NoxInteractionMetrics(windowStartedAt: snapshot.capturedAt)
        metrics.scrollEventCount = 2
        return pipeline.evaluate(
            snapshot: snapshot,
            capabilities: NoxCapabilityState(
                accessibilityGranted: true,
                screenRecordingGranted: true,
                appAwarenessAvailable: true,
                windowAwarenessAvailable: true,
                interactionSignalsAvailable: true
            ),
            metrics: metrics,
            stableDurationSeconds: 20,
            recentSwitchCount: 0,
            resetDominance: true
        )
    }
}
