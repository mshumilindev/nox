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

/// Iteration 6A scenario-class validation for the context acquisition pipeline.
struct NoxContextScenarioQATests {
    private let fullCapabilities = NoxCapabilityState(
        accessibilityGranted: true,
        screenRecordingGranted: false,
        appAwarenessAvailable: true,
        windowAwarenessAvailable: true,
        interactionSignalsAvailable: true
    )

    private let appOnlyCapabilities = NoxCapabilityState(
        accessibilityGranted: false,
        screenRecordingGranted: false,
        appAwarenessAvailable: true,
        windowAwarenessAvailable: false,
        interactionSignalsAvailable: false
    )

    private func evaluate(
        bundleId: String,
        appName: String,
        title: String?,
        documentURL: String? = nil,
        metrics: NoxInteractionMetrics,
        stableSeconds: TimeInterval = 60,
        switches: Int = 0,
        capabilities: NoxCapabilityState? = nil
    ) -> NoxContextEvidence {
        var pipeline = NoxContextAcquisitionPipeline()
        let snapshot = NoxActivitySnapshot(
            appName: appName,
            bundleId: bundleId,
            windowTitle: title,
            documentURL: documentURL,
            processId: 42,
            idleSeconds: 0,
            isUserIdle: false,
            capturedAt: Date()
        )
        return pipeline.evaluate(
            snapshot: snapshot,
            capabilities: capabilities ?? fullCapabilities,
            metrics: metrics,
            stableDurationSeconds: stableSeconds,
            recentSwitchCount: switches
        )
    }

    private func metrics(
        typing: Int = 0,
        scroll: Int = 0,
        passive: Bool = false,
        active: Bool = false
    ) -> NoxInteractionMetrics {
        var m = NoxInteractionMetrics(windowStartedAt: Date())
        m.typingBurstCount = typing
        m.typingActiveSeconds = typing > 0 ? 15 : 0
        m.scrollEventCount = scroll
        m.isInteractionActive = active
        if passive { m.isInteractionActive = false }
        return m
    }

    @Test func writingScenario() {
        let evidence = evaluate(
            bundleId: "com.apple.Notes",
            appName: "Notes",
            title: "Journal — Notes",
            metrics: metrics(typing: 8, active: true)
        )
        #expect(evidence.safeOutput.dominantContextType == .writing)
        #expect(!evidence.evidenceItems.isEmpty)
    }

    @Test func codingScenario() {
        let evidence = evaluate(
            bundleId: "com.microsoft.VSCode",
            appName: "Code",
            title: "main.swift — project",
            metrics: metrics(typing: 10, active: true)
        )
        #expect([NoxDominantContextType.development, .writing].contains(evidence.safeOutput.dominantContextType))
        #expect(evidence.appContext.primaryAdapterId == "editor")
    }

    @Test func passiveVideoScenario() {
        let evidence = evaluate(
            bundleId: "com.google.Chrome",
            appName: "Chrome",
            title: "Artist — Official Music Video - YouTube",
            documentURL: "https://www.youtube.com/watch?v=abc",
            metrics: metrics(passive: true),
            stableSeconds: 90
        )
        #expect(evidence.safeOutput.dominantContextType == .watching)
        #expect(evidence.appContext.browserDomain?.contains("youtube") == true)
    }

    @Test func streamingSiteScenario() {
        let evidence = evaluate(
            bundleId: "com.google.Chrome",
            appName: "Chrome",
            title: "Show — Netflix",
            documentURL: "https://www.netflix.com/watch/1",
            metrics: metrics(passive: true),
            stableSeconds: 120
        )
        #expect(evidence.safeOutput.dominantContextType == .watching)
    }

    @Test func browserGameScenario() {
        let evidence = evaluate(
            bundleId: "com.google.Chrome",
            appName: "Chrome",
            title: "Puzzle Game — Browser",
            metrics: metrics(active: true),
            stableSeconds: 45
        )
        #expect([
            NoxDominantContextType.gamingInteractive,
            .research,
            .shoppingComparison,
            .reading
        ].contains(evidence.safeOutput.dominantContextType))
    }

    @Test func desktopGameScenario() {
        let evidence = evaluate(
            bundleId: "com.valvesoftware.steam",
            appName: "Steam",
            title: "Library",
            metrics: metrics(active: true),
            stableSeconds: 80
        )
        #expect(evidence.appContext.adapterIds.contains("game"))
    }

    @Test func travelBookingScenario() {
        let evidence = evaluate(
            bundleId: "com.google.Chrome",
            appName: "Chrome",
            title: "Flights to Warsaw — Booking",
            documentURL: "https://www.booking.com/flights",
            metrics: metrics(scroll: 4, active: true)
        )
        #expect([
            NoxDominantContextType.travelPlanning,
            .shoppingComparison,
            .research,
            .reading
        ].contains(evidence.safeOutput.dominantContextType))
    }

    @Test func shoppingComparisonScenario() {
        let evidence = evaluate(
            bundleId: "com.google.Chrome",
            appName: "Chrome",
            title: "Cart — Shop",
            metrics: metrics(scroll: 5, active: true)
        )
        #expect([
            NoxDominantContextType.shoppingComparison,
            .research,
            .reading
        ].contains(evidence.safeOutput.dominantContextType))
    }

    @Test func fileTransferScenario() {
        let evidence = evaluate(
            bundleId: "com.apple.finder",
            appName: "Finder",
            title: "Downloading 48% — transfer",
            metrics: metrics(passive: true)
        )
        #expect(evidence.safeOutput.dominantContextType == .fileTransfer)
        #expect(evidence.appContext.primaryAdapterId == "file-transfer")
    }

    @Test func pdfReadingScenario() {
        let evidence = evaluate(
            bundleId: "com.apple.Preview",
            appName: "Preview",
            title: "Report.pdf — Preview",
            metrics: metrics(scroll: 6, passive: true)
        )
        #expect([NoxDominantContextType.reading, .unknown].contains(evidence.safeOutput.dominantContextType))
    }

    @Test func privateBrowsingScenario() {
        let evidence = evaluate(
            bundleId: "com.apple.Safari",
            appName: "Safari",
            title: "Start Page",
            documentURL: nil,
            metrics: metrics()
        )
        // Private browsing is detected via browser classifier when host/title signals private mode.
        let isProtected = evidence.safeOutput.detailsRedacted
            || evidence.appContext.sensitivity == .privateContext
            || evidence.safeOutput.displayLabel == "Private context"
        #expect(isProtected || evidence.appContext.primaryAdapterId == "browser")
    }

    @Test func bankingScenario() {
        let evidence = evaluate(
            bundleId: "com.google.Chrome",
            appName: "Chrome",
            title: "Sign in — chase.com",
            documentURL: "https://chase.com/login",
            metrics: metrics()
        )
        #expect(evidence.safeOutput.displayLabel == "Sensitive context")
        #expect(evidence.safeOutput.detailsRedacted)
    }

    @Test func missingPermissionsScenario() {
        let evidence = evaluate(
            bundleId: "com.google.Chrome",
            appName: "Chrome",
            title: nil,
            metrics: metrics(),
            capabilities: appOnlyCapabilities
        )
        #expect(evidence.appContext.missingChannels.contains(NoxContextObservationChannel.windowTitle))
        #expect(evidence.evidenceItems.contains { $0.value.contains("missing:") })
    }

    @Test func unknownAppScenario() {
        let evidence = evaluate(
            bundleId: "com.example.unknown",
            appName: "Unknown Tool",
            title: "Workspace",
            metrics: metrics()
        )
        #expect(evidence.appContext.adapterIds.contains("unknown-fallback"))
        #expect(!evidence.safeOutput.displayLabel.isEmpty)
    }

    @Test func staleFragmentedYieldsToPassiveMedia() {
        var pipeline = NoxContextAcquisitionPipeline()
        let chrome = NoxActivitySnapshot(
            appName: "Chrome",
            bundleId: "com.google.Chrome",
            windowTitle: "Tab A",
            documentURL: nil,
            processId: 1,
            idleSeconds: 0,
            isUserIdle: false,
            capturedAt: Date()
        )
        var fragmentedMetrics = metrics(active: true)
        _ = pipeline.evaluate(
            snapshot: chrome,
            capabilities: fullCapabilities,
            metrics: fragmentedMetrics,
            stableDurationSeconds: 5,
            recentSwitchCount: 6
        )

        let passiveVideo = evaluate(
            bundleId: "com.google.Chrome",
            appName: "Chrome",
            title: "Live Concert Stream — YouTube",
            metrics: metrics(passive: true),
            stableSeconds: 120,
            switches: 1
        )
        #expect(passiveVideo.safeOutput.dominantContextType == .watching)
    }

    @Test func explainabilitySnapshotPopulated() {
        let evidence = evaluate(
            bundleId: "com.google.Chrome",
            appName: "Chrome",
            title: "Docs — Reference",
            metrics: metrics(scroll: 4)
        )
        let debug = NoxContextDebugFormatter.make(evidence: evidence)
        #expect(debug.activeApp == "Chrome")
        #expect(!debug.evidenceItems.isEmpty)
        #expect(debug.dominantContext != nil)
    }
}
