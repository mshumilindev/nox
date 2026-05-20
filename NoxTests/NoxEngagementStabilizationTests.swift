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

struct NoxEngagementStabilizationTests {

    @Test func shortUtilitySwitchWithoutInteractionIsTransient() {
        var stabilizer = NoxEngagementStabilizer()
        let start = Date()

        _ = stabilizer.ingest(
            snapshot: snapshot(appName: "Finder", bundleId: "com.apple.finder", at: start),
            metrics: quietMetrics(at: start)
        )

        let decision = stabilizer.ingest(
            snapshot: snapshot(appName: "Cursor", bundleId: "com.todesktop.230313mzl4w4u92", at: start.addingTimeInterval(0.55)),
            metrics: quietMetrics(at: start.addingTimeInterval(0.55))
        )

        #expect(decision.closedTransient?.phase == .transientTraversal)
        #expect(decision.closedTransient?.snapshot.bundleId == "com.apple.finder")
    }

    @Test func shortHighInteractionEditorVisitHardStabilizes() {
        var stabilizer = NoxEngagementStabilizer()
        let start = Date()

        _ = stabilizer.ingest(
            snapshot: snapshot(appName: "Cursor", bundleId: "com.todesktop.230313mzl4w4u92", at: start),
            metrics: quietMetrics(at: start)
        )

        let decision = stabilizer.ingest(
            snapshot: snapshot(appName: "Cursor", bundleId: "com.todesktop.230313mzl4w4u92", at: start.addingTimeInterval(2)),
            metrics: typingMetrics(at: start.addingTimeInterval(2))
        )

        #expect(decision.becameHard)
        #expect(decision.state.phase == .hardStabilized)
    }

    @Test func microTraversalMergesBackIntoPreviousHardContinuity() {
        var stabilizer = NoxEngagementStabilizer()
        let start = Date()
        let cursor = snapshot(appName: "Cursor", bundleId: "com.todesktop.230313mzl4w4u92", at: start)

        _ = stabilizer.ingest(snapshot: cursor, metrics: quietMetrics(at: start))
        _ = stabilizer.ingest(
            snapshot: snapshot(appName: "Cursor", bundleId: cursor.bundleId, at: start.addingTimeInterval(6)),
            metrics: quietMetrics(at: start.addingTimeInterval(6))
        )
        _ = stabilizer.ingest(
            snapshot: snapshot(appName: "Finder", bundleId: "com.apple.finder", at: start.addingTimeInterval(6.4)),
            metrics: quietMetrics(at: start.addingTimeInterval(6.4))
        )
        _ = stabilizer.ingest(
            snapshot: snapshot(appName: "Safari", bundleId: "com.apple.Safari", at: start.addingTimeInterval(7.1)),
            metrics: quietMetrics(at: start.addingTimeInterval(7.1))
        )
        _ = stabilizer.ingest(
            snapshot: snapshot(appName: "Cursor", bundleId: cursor.bundleId, at: start.addingTimeInterval(7.5)),
            metrics: quietMetrics(at: start.addingTimeInterval(7.5))
        )
        let merged = stabilizer.ingest(
            snapshot: snapshot(appName: "Cursor", bundleId: cursor.bundleId, at: start.addingTimeInterval(13)),
            metrics: quietMetrics(at: start.addingTimeInterval(13))
        )

        #expect(merged.continuityMerge?.bundleId == cursor.bundleId)
        #expect(merged.continuityMerge?.absorbedTraversalCount == 2)
    }

    private func snapshot(
        appName: String,
        bundleId: String,
        at date: Date
    ) -> NoxActivitySnapshot {
        NoxActivitySnapshot(
            appName: appName,
            bundleId: bundleId,
            windowTitle: nil,
            documentURL: nil,
            processId: nil,
            idleSeconds: 0,
            isUserIdle: false,
            capturedAt: date
        )
    }

    private func quietMetrics(at date: Date) -> NoxInteractionMetrics {
        NoxInteractionMetrics(windowStartedAt: date)
    }

    private func typingMetrics(at date: Date) -> NoxInteractionMetrics {
        var metrics = NoxInteractionMetrics(windowStartedAt: date)
        metrics.typingBurstCount = 4
        metrics.typingActiveSeconds = 6
        metrics.isInteractionActive = true
        return metrics
    }
}
