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

struct NoxSemanticInferenceEngineTests {

    private let engine = NoxSemanticInferenceEngine()
    private let fullCapabilities = NoxCapabilityState(
        accessibilityGranted: true,
        screenRecordingGranted: false,
        appAwarenessAvailable: true,
        windowAwarenessAvailable: true,
        interactionSignalsAvailable: true
    )

    private func context(
        bundleId: String? = "com.openai.chat",
        appName: String? = "ChatGPT",
        windowTitle: String? = nil,
        domain: String? = "chatgpt.com",
        metrics: NoxInteractionMetrics,
        switches: Int = 0,
        timeInApp: TimeInterval = 300,
        browserCategory: NoxBrowserCategory = .aiWorkflow,
        fragmentationSwitchCount: Int? = nil
    ) -> NoxSemanticContext {
        let effectiveFragmentation = fragmentationSwitchCount
            ?? Self.effectiveFragmentationCount(switches: switches, timeInApp: timeInApp)
        return NoxSemanticContext(
            capabilities: fullCapabilities,
            bundleId: bundleId,
            appName: appName,
            windowTitle: windowTitle,
            domain: domain,
            metrics: metrics,
            timeInCurrentApp: timeInApp,
            recentSwitchCount: switches,
            isUserIdle: false,
            idleSeconds: 0,
            nearbyBundleIds: [],
            focusHint: .unknown,
            hourOfDay: 14,
            observationContinuitySeconds: 600,
            browserCategory: browserCategory,
            dominantContextType: nil,
            dominantContextConfidence: 0,
            fragmentationSwitchCount: effectiveFragmentation
        )
    }

    private static func effectiveFragmentationCount(switches: Int, timeInApp: TimeInterval) -> Int {
        if timeInApp >= 120 { return 0 }
        if timeInApp >= 60 { return max(0, switches - 3) }
        if timeInApp >= 30 { return max(0, switches - 1) }
        return switches
    }

    @Test func semanticMemoryMetadataKeepsDetailedTechnicalContext() throws {
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.typingBurstCount = 6
        metrics.typingActiveSeconds = 18
        metrics.scrollEventCount = 2
        metrics.mouseEventCount = 7
        metrics.isInteractionActive = true

        let semanticContext = context(
            bundleId: "com.todesktop.230313mzl4w4u92",
            appName: "Cursor",
            windowTitle: "Nox - Cursor",
            domain: "github.com",
            metrics: metrics,
            switches: 3,
            timeInApp: 180,
            browserCategory: .development
        )
        let inference = NoxSemanticInference(
            state: .writing,
            confidence: 0.82,
            displayPhrase: "Writing-heavy technical work",
            reasons: [NoxSemanticReason(signal: "interaction", detail: "typing-heavy")],
            fusionLabel: .likelyAIAssistedWork,
            fusionConfidence: 0.76,
            fusionPhrase: "AI-assisted development",
            sensitivityLevel: .normal,
            browserCategory: .development,
            aiWorkflow: .codeOriented,
            aiWorkflowPhrase: "Code-oriented AI workflow",
            shouldSurface: true
        )

        let json = try #require(NoxSemanticMemoryMetadata.build(
            inference: inference,
            context: semanticContext,
            appName: "Cursor",
            bundleId: "com.todesktop.230313mzl4w4u92",
            appNames: ["Cursor", "ChatGPT"]
        ))
        let data = try #require(json.data(using: .utf8))
        let payload = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let interaction = try #require(payload["interaction"] as? [String: Any])

        #expect(payload["current_app_name"] as? String == "Cursor")
        #expect(payload["current_bundle_id"] as? String == "com.todesktop.230313mzl4w4u92")
        #expect(payload["window_title"] as? String == "Nox - Cursor")
        #expect(payload["domain"] as? String == "github.com")
        #expect(payload["semantic_state"] as? String == "writing")
        #expect(payload["fusion_label"] as? String == "likelyAIAssistedWork")
        #expect(payload["browser_category"] as? String == "development")
        #expect((payload["span_app_names"] as? [String]) == ["Cursor", "ChatGPT"])
        #expect((interaction["typing_density"] as? Double ?? 0) > 0)
        #expect(interaction["is_interaction_active"] as? Bool == true)
    }

    @Test func semanticMemoryMetadataSkipsSensitiveDetails() {
        let inference = NoxSemanticInference(
            state: .reading,
            confidence: 0.8,
            displayPhrase: "Private context",
            reasons: [NoxSemanticReason(signal: "domain", detail: "private")],
            fusionLabel: .likelyPassiveEntertainment,
            fusionConfidence: 0.7,
            fusionPhrase: "Private context",
            sensitivityLevel: .privateContext,
            browserCategory: .privateBrowsing,
            aiWorkflow: nil,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )

        let json = NoxSemanticMemoryMetadata.build(
            inference: inference,
            context: context(metrics: NoxInteractionMetrics(windowStartedAt: Date())),
            appName: "Safari",
            bundleId: "com.apple.Safari"
        )

        #expect(json == nil)
    }

    @Test func chatGPTHighTypingIsWritingHeavy() {
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.typingBurstCount = 10
        metrics.typingActiveSeconds = 20
        let result = engine.infer(context: context(metrics: metrics))
        #expect(result.state == .writing || result.aiWorkflow == .promptWriting)
        #expect(result.confidence >= 0.4)
        #expect(result.displayPhrase.localizedCaseInsensitiveContains("writing") ||
                (result.aiWorkflowPhrase?.localizedCaseInsensitiveContains("prompt") == true))
    }

    @Test func chatGPTHighScrollLowTypingIsReadingHeavy() {
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.scrollEventCount = 12
        metrics.typingBurstCount = 0
        let result = engine.infer(context: context(metrics: metrics))
        #expect(result.state == .reading || result.aiWorkflow == .passiveAIReading)
        #expect(result.displayPhrase.localizedCaseInsensitiveContains("reading") ||
                result.aiWorkflowPhrase?.localizedCaseInsensitiveContains("reading") == true)
    }

    @Test func travelDomainsSuggestTravelPlanning() {
        let result = engine.infer(
            context: context(
                bundleId: "com.apple.Safari",
                appName: "Safari",
                domain: "booking.com",
                metrics: NoxInteractionMetrics(windowStartedAt: Date()),
                browserCategory: .travel
            )
        )
        #expect(result.fusionLabel == .likelyTravelPlanning)
        #expect(result.fusionPhrase.localizedCaseInsensitiveContains("travel"))
    }

    @Test func netflixLowInteractionIsPassive() {
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.isInteractionActive = false
        let result = engine.infer(
            context: context(
                bundleId: "com.apple.Safari",
                appName: "Safari",
                domain: "netflix.com",
                metrics: metrics,
                browserCategory: .entertainment
            )
        )
        #expect(result.state == .passiveConsumption || result.fusionLabel == .likelyPassiveEntertainment)
    }

    @Test func streamingContextOverridesRecentSwitching() {
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.isInteractionActive = false
        let result = engine.infer(
            context: context(
                bundleId: "com.google.Chrome",
                appName: "Chrome",
                windowTitle: "Anaconda - HBO Max",
                domain: "play.hbomax.com",
                metrics: metrics,
                switches: 7,
                browserCategory: .entertainment
            )
        )

        #expect(result.state == .passiveConsumption)
        #expect(result.displayPhrase == "Watching")
    }

    @Test func sustainedPassiveAmbiguousBrowserBecomesPassiveViewing() {
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.isInteractionActive = false
        metrics.interactionIdleSeconds = 45

        let result = engine.infer(
            context: context(
                bundleId: "com.google.Chrome",
                appName: "Chrome",
                windowTitle: "LELEKA - Ridnym (LIVE)",
                domain: "youtube.com",
                metrics: metrics,
                switches: 5,
                timeInApp: 120,
                browserCategory: .ambiguous
            )
        )

        #expect(result.state == .passiveConsumption)
        #expect(result.fusionLabel == .likelyPassiveEntertainment)
        #expect(
            result.reasons.contains {
                ["interaction_shape", "media_context", "dominant_context"].contains($0.signal)
            }
        )
    }

    @Test func hboMaxDomainIsEntertainment() {
        let result = NoxBrowserContextClassifier().classify(
            bundleId: "com.google.Chrome",
            windowTitle: "Anaconda - HBO Max",
            domain: "play.hbomax.com"
        )

        #expect(result.category == .entertainment)
        #expect(result.isAmbiguous == false)
    }

    @Test func dynamicUnknownStreamingSiteClassifiesAsEntertainment() {
        let result = NoxBrowserContextClassifier().classify(
            bundleId: "com.google.Chrome",
            windowTitle: "Episode player - Watch now",
            domain: "play.streambox.example/video/watch"
        )

        #expect(result.category == .entertainment)
    }

    @Test func dynamicUnknownTravelSiteClassifiesAsTravel() {
        let result = NoxBrowserContextClassifier().classify(
            bundleId: "com.apple.Safari",
            windowTitle: "Hotel booking - room availability",
            domain: "staywild.example/hotels/search"
        )

        #expect(result.category == .travel)
    }

    @Test func dynamicUnknownShoppingSiteClassifiesAsShopping() {
        let result = NoxBrowserContextClassifier().classify(
            bundleId: "com.apple.Safari",
            windowTitle: "Checkout - payment method",
            domain: "market-example.test/cart"
        )

        #expect(result.category == .shopping)
    }

    @Test func dynamicUnknownDocsSiteClassifiesAsReference() {
        let result = NoxBrowserContextClassifier().classify(
            bundleId: "com.apple.Safari",
            windowTitle: "SDK API Reference - Getting started",
            domain: "newtool.dev/docs/api"
        )

        #expect(result.category == .reference)
    }

    @Test func torrentAppSurfacesAsFileTransferPeriod() {
        let result = engine.infer(
            context: context(
                bundleId: "org.qbittorrent.qBittorrent",
                appName: "qBittorrent",
                windowTitle: "Download queue - seeding",
                domain: nil,
                metrics: NoxInteractionMetrics(windowStartedAt: Date()),
                switches: 6,
                browserCategory: .unknown
            )
        )

        #expect(result.fusionLabel == .likelyFileTransfer)
        #expect(NoxSemanticLabelCatalog.semanticPulseTitle(from: result) == "File transfer")
    }

    @Test func unknownGameAppSurfacesAsGameSession() {
        let result = engine.infer(
            context: context(
                bundleId: "com.example.weirdgame",
                appName: "Strange Game Launcher",
                windowTitle: "Playing game",
                domain: nil,
                metrics: NoxInteractionMetrics(windowStartedAt: Date()),
                browserCategory: .unknown
            )
        )

        #expect(result.fusionLabel == .likelyGaming)
        #expect(NoxSemanticLabelCatalog.semanticPulseTitle(from: result) == "Playing")
    }

    @Test func browserGameContextSurfacesAsGameSession() {
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.isInteractionActive = true
        metrics.mouseEventCount = 8
        let result = engine.infer(
            context: context(
                bundleId: "com.google.Chrome",
                appName: "Chrome",
                windowTitle: "Flash game - browser arcade",
                domain: "oddsite.example/play",
                metrics: metrics,
                switches: 6,
                browserCategory: .ambiguous
            )
        )

        #expect(result.fusionLabel == .likelyGaming)
        #expect(NoxSemanticLabelCatalog.semanticPulseTitle(from: result) == "Playing")
    }

    @Test func unknownInteractiveBrowserUseFallsBackToInteractiveBrowsing() {
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.isInteractionActive = true
        metrics.mouseEventCount = 10
        let result = engine.infer(
            context: context(
                bundleId: "com.apple.Safari",
                appName: "Safari",
                windowTitle: "Untitled web app",
                domain: "strange-tool.example",
                metrics: metrics,
                switches: 6,
                browserCategory: .ambiguous
            )
        )

        #expect(result.fusionLabel == .likelyInteractiveBrowsing)
        #expect(NoxSemanticLabelCatalog.semanticPulseTitle(from: result) == "Interactive browsing")
    }

    @Test func unknownCreativeAppSurfacesAsCreativeWork() {
        let result = engine.infer(
            context: context(
                bundleId: "com.example.canvas",
                appName: "Canvas Studio",
                windowTitle: "Video edit timeline",
                domain: nil,
                metrics: NoxInteractionMetrics(windowStartedAt: Date()),
                browserCategory: .unknown
            )
        )

        #expect(result.fusionLabel == .likelyCreativeWork)
        #expect(NoxSemanticLabelCatalog.semanticPulseTitle(from: result) == "Creative work")
    }

    @Test func devAppsWithTypingSuggestWork() {
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.typingBurstCount = 8
        metrics.typingActiveSeconds = 18
        let result = engine.infer(
            context: context(
                bundleId: "com.apple.dt.Xcode",
                appName: "Xcode",
                domain: nil,
                metrics: metrics,
                browserCategory: .development
            )
        )
        #expect(result.fusionLabel == .likelyWorkRelated || result.state == .writing)
    }

    @Test func adultDomainIsPrivateWithoutExplicitLabel() {
        let result = engine.infer(
            context: context(
                bundleId: "com.apple.Safari",
                appName: "Safari",
                domain: "pornhub.com",
                metrics: NoxInteractionMetrics(windowStartedAt: Date()),
                browserCategory: .privateBrowsing
            )
        )
        #expect(result.sensitivityLevel == .privateContext)
        #expect(!result.displayPhrase.localizedCaseInsensitiveContains("porn"))
        #expect(result.displayPhrase.localizedCaseInsensitiveContains("private") ||
                result.fusionPhrase.localizedCaseInsensitiveContains("private"))
    }

    @Test func bankingDomainIsSensitive() {
        let sensitivity = NoxSensitiveContextHandler.sensitivity(
            domain: "chase.com",
            title: "Chase Online Banking",
            bundleId: "com.apple.Safari"
        )
        #expect(sensitivity == .sensitive)
        let title = NoxSensitiveContextHandler.sanitizedTitle("Chase Online Banking", sensitivity: sensitivity)
        #expect(title == "Sensitive context")
    }

    @Test func lowConfidenceStaysHidden() {
        let result = engine.infer(
            context: context(
                bundleId: "com.apple.Safari",
                appName: "Safari",
                domain: nil,
                metrics: NoxInteractionMetrics(windowStartedAt: Date()),
                browserCategory: .ambiguous
            )
        )
        if result.confidence < 0.4 {
            #expect(result.shouldSurface == false)
        }
    }

    @Test func frequentSwitchingIsFragmented() {
        let result = engine.infer(
            context: context(
                metrics: NoxInteractionMetrics(windowStartedAt: Date()),
                switches: 5,
                timeInApp: 15,
                fragmentationSwitchCount: 5
            )
        )
        #expect(result.state == .fragmentedInteraction)
    }

    @Test func sustainedTypingIsSustainedOrWriting() {
        var metrics = NoxInteractionMetrics(windowStartedAt: Date())
        metrics.typingBurstCount = 6
        metrics.typingActiveSeconds = 15
        let result = engine.infer(
            context: context(
                bundleId: "com.apple.dt.Xcode",
                appName: "Xcode",
                metrics: metrics,
                timeInApp: 400,
                browserCategory: .development
            )
        )
        #expect(result.state == .sustainedInteraction || result.state == .writing)
    }
}
