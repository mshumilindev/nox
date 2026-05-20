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

struct NoxContextFrameworkTests {
    private let capabilities = NoxCapabilityState(
        accessibilityGranted: true,
        screenRecordingGranted: false,
        appAwarenessAvailable: true,
        windowAwarenessAvailable: true,
        interactionSignalsAvailable: true
    )

    private func snapshot(
        bundleId: String,
        appName: String,
        title: String?
    ) -> NoxActivitySnapshot {
        NoxActivitySnapshot(
            appName: appName,
            bundleId: bundleId,
            windowTitle: title,
            documentURL: nil,
            processId: 1234,
            idleSeconds: 0,
            isUserIdle: false,
            capturedAt: Date()
        )
    }

    @Test func genericAdapterProducesContextForUnknownApp() {
        var pipeline = NoxContextAcquisitionPipeline()
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.scrollEventCount = 8
        metrics.typingBurstCount = 0

        let evidence = pipeline.evaluate(
            snapshot: snapshot(bundleId: "com.example.unknown", appName: "Unknown Tool", title: "Notes — Unknown Tool"),
            capabilities: capabilities,
            metrics: metrics,
            stableDurationSeconds: 40,
            recentSwitchCount: 0
        )

        #expect(evidence.safeOutput.displayLabel != "Unknown Tool")
        #expect(evidence.semantic.candidates.isEmpty == false)
    }

    @Test func sensitiveContextRedactsToPrivateLabel() {
        var pipeline = NoxContextAcquisitionPipeline()
        let evidence = pipeline.evaluate(
            snapshot: snapshot(
                bundleId: "com.google.Chrome",
                appName: "Chrome",
                title: "Sign in — chase.com"
            ),
            capabilities: capabilities,
            metrics: NoxInteractionMetrics(windowStartedAt: Date()),
            stableDurationSeconds: 10,
            recentSwitchCount: 0
        )

        #expect(evidence.safeOutput.detailsRedacted)
        #expect(evidence.safeOutput.displayLabel == "Sensitive context")
    }

    @Test func editorAdapterFavorsDevelopmentOnTyping() {
        var pipeline = NoxContextAcquisitionPipeline()
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.typingBurstCount = 8
        metrics.typingActiveSeconds = 20
        metrics.isInteractionActive = true

        let evidence = pipeline.evaluate(
            snapshot: snapshot(
                bundleId: "com.microsoft.VSCode",
                appName: "Code",
                title: "main.ts — project"
            ),
            capabilities: capabilities,
            metrics: metrics,
            stableDurationSeconds: 60,
            recentSwitchCount: 0
        )

        #expect(evidence.safeOutput.dominantContextType == .development || evidence.safeOutput.dominantContextType == .writing)
    }

    @Test func youtubeMusicVideoWithScrollInfersWatching() {
        var pipeline = NoxContextAcquisitionPipeline()
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.scrollEventCount = 12
        metrics.isInteractionActive = true

        let evidence = pipeline.evaluate(
            snapshot: snapshot(
                bundleId: "com.google.Chrome",
                appName: "Chrome",
                title: "BAD OMENS - Specter (Official Music Video) - YouTube"
            ),
            capabilities: capabilities,
            metrics: metrics,
            stableDurationSeconds: 120,
            recentSwitchCount: 1
        )

        #expect(evidence.safeOutput.dominantContextType == .watching)
        #expect(evidence.safeOutput.displayLabel == "Watching")
    }

    @Test func sustainedPassiveBrowserInfersWatching() {
        var pipeline = NoxContextAcquisitionPipeline()
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.isInteractionActive = false

        let evidence = pipeline.evaluate(
            snapshot: snapshot(
                bundleId: "com.google.Chrome",
                appName: "Chrome",
                title: "Artist Name — Live Performance | Eurovision 2026"
            ),
            capabilities: capabilities,
            metrics: metrics,
            stableDurationSeconds: 50,
            recentSwitchCount: 4
        )

        #expect(evidence.safeOutput.dominantContextType == .watching)
    }

    @Test func dominanceRetainsDevelopmentOverListeningWhenTyping() {
        let resolver = NoxDominantContextResolver()
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.typingBurstCount = 6
        metrics.typingActiveSeconds = 15
        metrics.isInteractionActive = true

        let input = NoxContextAdapterInput(
            snapshot: snapshot(bundleId: "com.microsoft.VSCode", appName: "Code", title: "app.swift"),
            capabilities: NoxContextCapabilityProfile.from(capabilities),
            metrics: metrics,
            activityCategory: .development,
            sanitizedTitle: "app.swift",
            domain: nil,
            stableDurationSeconds: 90,
            recentSwitchCount: 0,
            sensitivityLevel: .normal
        )

        let established: [NoxContextCandidate] = [
            NoxContextCandidate(
                id: "dev",
                contextType: .development,
                confidence: 0.85,
                dominanceWeight: 0.88,
                sourceAdapterId: "editor-like",
                signalNames: []
            )
        ]
        _ = resolver.resolve(ranked: established, input: input, adapterReasons: [])

        let challenged: [NoxContextCandidate] = [
            NoxContextCandidate(
                id: "listen",
                contextType: .listening,
                confidence: 0.74,
                dominanceWeight: 0.76,
                sourceAdapterId: "media-like",
                signalNames: []
            ),
            NoxContextCandidate(
                id: "dev",
                contextType: .development,
                confidence: 0.7,
                dominanceWeight: 0.72,
                sourceAdapterId: "editor-like",
                signalNames: []
            )
        ]

        let result = resolver.resolve(ranked: challenged, input: input, adapterReasons: [])
        #expect(result.dominant?.contextType == .development)
    }
}
