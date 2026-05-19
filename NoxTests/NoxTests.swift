import Foundation
import Testing
@testable import Nox

struct NoxPresenceStateTests {

    @Test @MainActor func defaultPresenceIsQuiet() {
        let environment = AppEnvironment()
        #expect(environment.presence == .quiet)
    }

    @Test func presenceTitlesExist() {
        for state in NoxPresenceState.allCases {
            #expect(!state.title.isEmpty)
            #expect(!state.symbolName.isEmpty)
        }
    }
}

struct NoxPresenceEngineTests {

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

struct NoxLiveSignalDeduplicatorTests {

    @Test func suppressesActiveAfterSwitch() {
        let now = Date()
        let prior = NoxLiveSignal(
            id: "1",
            timestamp: now,
            text: "Switched to Safari",
            kind: .app
        )
        let next = NoxLiveSignal(
            id: "2",
            timestamp: now.addingTimeInterval(4),
            text: "Safari active",
            kind: .app
        )
        #expect(NoxLiveSignalDeduplicator.shouldAccept(next, in: [prior]) == false)
    }
}

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
        #expect(rows.contains { $0.feature == "App context" && $0.status == "Active" })
        #expect(rows.contains { $0.feature == "Window context" && $0.status == "Additional context available" })
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

@MainActor
struct NoxPresenceStabilizerTests {

    @Test func holdsBriefIdleFluctuation() {
        let stabilizer = NoxPresenceStabilizer()
        stabilizer.reset(to: .active)
        let first = stabilizer.resolve(proposed: .idle, at: Date())
        #expect(first == .active)
        let later = stabilizer.resolve(
            proposed: .idle,
            at: Date().addingTimeInterval(65)
        )
        #expect(later == .idle)
    }
}

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

struct NoxClassifierTests {

    @Test func classifiesXcodeAsDevelopment() {
        let classifier = NoxAppClassifier()
        let category = classifier.classify(
            bundleId: "com.apple.dt.Xcode",
            appName: "Xcode",
            windowTitle: "Nox — Xcode"
        )
        #expect(category == .development)
    }

    @Test func githubTitleRefinesSafari() {
        let classifier = NoxAppClassifier()
        let category = classifier.classify(
            bundleId: "com.apple.Safari",
            appName: "Safari",
            windowTitle: "GitHub - user/repo - Pull Request #442"
        )
        #expect(category == .development)
    }

    @Test func recognizesCommonNonLLMAppsCoarsely() {
        let classifier = NoxAppClassifier()

        #expect(classifier.classify(
            bundleId: "com.figma.Desktop",
            appName: "Figma",
            windowTitle: "Design system"
        ) == .creative)

        #expect(classifier.classify(
            bundleId: "com.microsoft.Word",
            appName: "Microsoft Word",
            windowTitle: "Proposal"
        ) == .productivity)

        #expect(classifier.classify(
            bundleId: "us.zoom.xos",
            appName: "zoom.us",
            windowTitle: "Team sync"
        ) == .communication)
    }

    @Test func classifiesChatGPTAsResearchNotUnknown() {
        let classifier = NoxAppClassifier()
        let category = classifier.classify(
            bundleId: "com.openai.chat",
            appName: "ChatGPT",
            windowTitle: "New chat"
        )
        #expect(category == .research)
        #expect(category.displayName != "Unknown")
    }

    @Test func resolvesLegacyUnknownCategoryFromAppIdentity() {
        let resolved = NoxActivityCategory.resolving(
            stored: .unknown,
            appName: "ChatGPT",
            bundleId: "com.openai.chat",
            windowTitle: nil
        )
        #expect(resolved == .research)
    }
}

struct NoxTitleSanitizerTests {

    @Test func stripsCursorSuffix() {
        let result = NoxTitleSanitizer.sanitize(
            appName: "Cursor",
            windowTitle: "shipwise — Cursor — Edited"
        )
        #expect(result == "shipwise")
    }
}

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

struct NoxPanelStateTests {

    @Test @MainActor func dashboardStartsClosed() {
        let panelState = NoxPanelState()
        #expect(panelState.isDashboardOpen == false)
    }
}

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

struct NoxSelfExclusionTests {

    @Test func excludesOwnBundleId() {
        let own = NoxSelfExclusion.ownBundleId ?? "dev.nox.Nox"
        #expect(NoxSelfExclusion.isExcluded(bundleId: own))
    }

    @Test func excludesAppNameNox() {
        #expect(NoxSelfExclusion.isExcluded(bundleId: "com.other.app", appName: "Nox"))
    }

    @Test func doesNotExcludeOtherApps() {
        #expect(!NoxSelfExclusion.isExcluded(bundleId: "com.apple.Safari", appName: "Safari"))
    }
}

struct NoxSemanticConfidenceTests {

    @Test func qualifiersRespectThresholds() {
        #expect(NoxSemanticConfidence.qualifier(for: 0.3).isEmpty)
        #expect(NoxSemanticConfidence.qualifier(for: 0.5) == "Possibly")
        #expect(NoxSemanticConfidence.qualifier(for: 0.7) == "Likely")
    }
}

struct NoxSemanticSpanStitcherTests {

    @Test func mergesNearbySpansWithSameWorkflowKey() {
        let t0 = Date()
        let a = span(id: "a", title: "AI research session", startedAt: t0, endedAt: t0.addingTimeInterval(600))
        let b = span(
            id: "b",
            title: "AI research session",
            startedAt: t0.addingTimeInterval(900),
            endedAt: t0.addingTimeInterval(1800)
        )
        let stitched = NoxSemanticSpanStitcher.stitch([a, b])
        #expect(stitched.count == 1)
        #expect(stitched[0].durationMs >= 1_200_000)
    }

    @Test func labelCatalogUsesHumanMemoryTitles() {
        let inference = NoxSemanticInference(
            state: .fragmentedInteraction,
            confidence: 0.7,
            displayPhrase: "Fragmented interaction pattern",
            reasons: [],
            fusionLabel: .unknown,
            fusionConfidence: 0,
            fusionPhrase: "",
            sensitivityLevel: .normal,
            browserCategory: .unknown,
            aiWorkflow: nil,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )
        let title = NoxSemanticLabelCatalog.memoryTitle(inference: inference, appName: nil)
        #expect(title == "Fragmented attention period")
        #expect(!title.localizedCaseInsensitiveContains("likely"))
    }

    private func span(
        id: String,
        title: String,
        startedAt: Date,
        endedAt: Date
    ) -> NoxSemanticMemorySpan {
        NoxSemanticMemorySpan(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            title: title,
            subtitle: "ChatGPT · Cursor",
            interactionStyle: "reading-heavy",
            semanticState: .reading,
            fusionLabel: .likelyAIAssistedWork,
            sensitivityLevel: .normal,
            confidence: 0.7,
            appNames: ["ChatGPT", "Cursor"],
            reasonsJson: nil
        )
    }
}

struct NoxContinuityMatcherTests {

    @Test func matchesSimilarAIDevEcosystem() {
        let signature = NoxContinuitySignature(
            ecosystemKey: "ai-dev",
            semanticType: .aiDevelopment,
            appTokens: ["chatgpt", "cursor"],
            semanticState: .writing,
            fusionLabel: .likelyAIAssistedWork,
            interactionProfile: "writing-heavy",
            densityProfile: "moderate"
        )
        let thread = NoxContinuityThread(
            id: "t1",
            semanticType: .aiDevelopment,
            title: "AI-assisted development continuity",
            dominantApps: ["Cursor", "Terminal"],
            dominantCategories: [],
            dominantDomains: [],
            continuitySignature: NoxContinuitySignature(
                ecosystemKey: "ai-dev",
                semanticType: .aiDevelopment,
                appTokens: ["cursor", "terminal", "github"],
                semanticState: .writing,
                fusionLabel: .likelyAIAssistedWork,
                interactionProfile: "writing-heavy",
                densityProfile: "dense"
            ),
            firstSeenAt: Date().addingTimeInterval(-4 * 3600),
            lastSeenAt: Date().addingTimeInterval(-2 * 3600),
            totalActiveDurationMs: 1_800_000,
            totalSessions: 2,
            totalResumptions: 1,
            continuityStrength: 0.75,
            recurrenceStrength: 0.4,
            interruptionPattern: "steady",
            currentStatus: .paused,
            recentMemoryIds: [],
            linkedSpanIds: ["s1"],
            linkedSessionIds: [],
            supportingSignals: [],
            confidence: 0.72,
            lastResumedAt: Date().addingTimeInterval(-2 * 3600),
            temporalPatterns: ["afternoon"],
            decayState: .fading,
            sensitivityLevel: .normal
        )
        let result = NoxContinuityMatcher.score(
            signature: signature,
            against: thread,
            at: Date(),
            gap: 2 * 3600
        )
        #expect(result.totalScore >= NoxContinuityConfidence.attachThreshold)
    }

    @Test func generalContinuityKeepsDistinctAppIdentity() {
        let inference = NoxSemanticInference(
            state: .activeInteraction,
            confidence: 0.7,
            displayPhrase: "",
            reasons: [],
            fusionLabel: .unknown,
            fusionConfidence: 0.2,
            fusionPhrase: "",
            sensitivityLevel: .normal,
            browserCategory: .unknown,
            aiWorkflow: nil,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )

        let figma = NoxContinuitySignature.from(
            inference: inference,
            appNames: ["Figma"],
            appName: "Figma"
        )
        let notes = NoxContinuitySignature.from(
            inference: inference,
            appNames: ["Notes"],
            appName: "Notes"
        )

        #expect(figma.semanticType == .general)
        #expect(notes.semanticType == .general)
        #expect(figma.ecosystemKey != notes.ecosystemKey)
    }

    @Test func resurfacingCopyIsHumble() {
        let thread = NoxContinuityThread(
            id: "t1",
            semanticType: .research,
            title: "Research continuity",
            dominantApps: ["Safari"],
            dominantCategories: [],
            dominantDomains: [],
            continuitySignature: NoxContinuitySignature(
                ecosystemKey: "research",
                semanticType: .research,
                appTokens: ["safari"],
                semanticState: .reading,
                fusionLabel: .likelyResearch,
                interactionProfile: "reading-heavy",
                densityProfile: "moderate"
            ),
            firstSeenAt: Date().addingTimeInterval(-86_400),
            lastSeenAt: Date().addingTimeInterval(-3 * 3600),
            totalActiveDurationMs: 2_400_000,
            totalSessions: 4,
            totalResumptions: 2,
            continuityStrength: 0.8,
            recurrenceStrength: 0.55,
            interruptionPattern: "steady",
            currentStatus: .resumed,
            recentMemoryIds: [],
            linkedSpanIds: [],
            linkedSessionIds: [],
            supportingSignals: [],
            confidence: 0.78,
            lastResumedAt: Date(),
            temporalPatterns: ["evening"],
            decayState: .active,
            sensitivityLevel: .normal
        )
        let match = NoxContinuityMatchResult(
            threadId: thread.id,
            totalScore: 0.8,
            components: [],
            isResumption: true
        )
        let resurfacing = NoxContinuityResurfacingPresenter.resurfacing(
            for: thread,
            match: match,
            at: Date()
        )
        #expect(resurfacing?.primaryText == "Research resumed")
        #expect(resurfacing?.primaryText.localizedCaseInsensitiveContains("should") == false)
        #expect(resurfacing?.primaryText.localizedCaseInsensitiveContains("unfinished") == false)
    }

    @Test func personalContinuityIsGeneralizedInPresentation() {
        let thread = NoxContinuityThread(
            id: "private",
            semanticType: .general,
            title: "Personal browsing continuity",
            dominantApps: ["Safari"],
            dominantCategories: [],
            dominantDomains: [],
            continuitySignature: NoxContinuitySignature(
                ecosystemKey: "general-safari",
                semanticType: .general,
                appTokens: ["safari"],
                semanticState: .unknown,
                fusionLabel: .unknown,
                interactionProfile: "mixed",
                densityProfile: "moderate"
            ),
            firstSeenAt: Date().addingTimeInterval(-3600),
            lastSeenAt: Date().addingTimeInterval(-1800),
            totalActiveDurationMs: 600_000,
            totalSessions: 2,
            totalResumptions: 1,
            continuityStrength: 0.8,
            recurrenceStrength: 0.5,
            interruptionPattern: "steady",
            currentStatus: .resumed,
            recentMemoryIds: [],
            linkedSpanIds: [],
            linkedSessionIds: [],
            supportingSignals: [],
            confidence: 0.8,
            lastResumedAt: Date(),
            temporalPatterns: ["evening"],
            decayState: .active,
            sensitivityLevel: .personal
        )

        #expect(NoxContinuityResurfacingPresenter.threadDisplayTitle(thread) == "Private continuity")
        #expect(NoxContinuityResurfacingPresenter.threadDetailLine(thread) == "Generalized continuity only")
    }
}

struct NoxPhilosophyTests {

    @Test func mottoPhasesAreStable() {
        #expect(NoxPhilosophy.inline == "I perform. I rest. I live. I am.")
        #expect(NoxPhilosophy.phases.count == 4)
    }

    @Test func restingPresenceEmphasizesRest() {
        let emphasis = NoxPhilosophy.emphasis(for: .resting)
        #expect(emphasis == .rest)
        #expect(NoxPhilosophy.lineOpacity(for: .rest, emphasis: emphasis) >
                NoxPhilosophy.lineOpacity(for: .perform, emphasis: emphasis))
    }

    @Test func focusedPresenceEmphasizesPerform() {
        let emphasis = NoxPhilosophy.emphasis(for: .flow)
        #expect(emphasis == .perform)
        #expect(NoxPhilosophy.lineOpacity(for: .perform, emphasis: emphasis) >
                NoxPhilosophy.lineOpacity(for: .rest, emphasis: emphasis))
    }
}

struct NoxLiveContextPresenterTests {

    @Test func suppressesTelemetryInPresentation() {
        let signals = [
            NoxLiveSignal(id: "1", timestamp: Date(), text: "Activity resumed", kind: .idle),
            NoxLiveSignal(
                id: "semantic-1",
                timestamp: Date(),
                text: "Fragmented attention period",
                kind: .awareness
            )
        ]
        let presentation = NoxLiveContextPresenter.present(signals: signals)
        #expect(presentation.pulse.contains { $0.text == "Fragmented attention period" })
        #expect(!presentation.detail.contains { $0.text == "Activity resumed" })
    }

    @Test func collapsesNearbyPulseDuplicates() {
        let now = Date()
        let signals = [
            NoxLiveSignal(
                id: "continuity-1",
                timestamp: now,
                text: "Fragmented attention period resumed",
                kind: .awareness
            ),
            NoxLiveSignal(
                id: "semantic-1",
                timestamp: now.addingTimeInterval(-20),
                text: "Fragmented attention period",
                kind: .awareness
            ),
            NoxLiveSignal(id: "idle-1", timestamp: now.addingTimeInterval(-30), text: "User idle", kind: .idle),
            NoxLiveSignal(id: "idle-2", timestamp: now.addingTimeInterval(-50), text: "User idle", kind: .idle)
        ]

        let presentation = NoxLiveContextPresenter.present(signals: signals)

        #expect(presentation.pulse.count == 1)
        #expect(presentation.pulse.first?.text == "Fragmented attention period")
        #expect(!presentation.detail.contains { $0.text.localizedCaseInsensitiveContains("user idle") })
    }

    @Test func collapsesPipelineAndSignalDuplicatePulse() {
        let now = Date()
        let signals = [
            NoxLiveSignal(
                id: "pulse-live-current",
                timestamp: now,
                text: "Focused in Codex",
                kind: .awareness,
                lifecycle: .transient(40)
            )
        ]

        let presentation = NoxLiveContextPresenter.present(
            signals: signals,
            contextLabel: "Focused in Codex"
        )

        #expect(presentation.pulse.map(\.text) == ["Focused in Codex"])
    }

    @Test func currentStreamingContextSuppressesStaleFragmentedPulse() {
        let now = Date()
        let inference = NoxSemanticInference(
            state: .passiveConsumption,
            confidence: 0.85,
            displayPhrase: "Watching",
            reasons: [],
            fusionLabel: .likelyPassiveEntertainment,
            fusionConfidence: 0.8,
            fusionPhrase: "Passive viewing",
            sensitivityLevel: .normal,
            browserCategory: .entertainment,
            aiWorkflow: nil,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )
        let signals = [
            NoxLiveSignal(
                id: "semantic-old",
                timestamp: now.addingTimeInterval(-30),
                text: "Fragmented attention period",
                kind: .awareness
            ),
            NoxLiveSignal(
                id: "semantic-current",
                timestamp: now,
                text: "Watching",
                kind: .awareness
            )
        ]

        let presentation = NoxLiveContextPresenter.present(
            signals: signals,
            semanticContext: inference
        )

        #expect(presentation.pulse.map(\.text) == ["Watching"])
    }

    @Test func contextualPassivePulseCanUseSafeWindowTitle() {
        let inference = NoxSemanticInference(
            state: .passiveConsumption,
            confidence: 0.85,
            displayPhrase: "Watching",
            reasons: [],
            fusionLabel: .likelyPassiveEntertainment,
            fusionConfidence: 0.8,
            fusionPhrase: "Passive viewing",
            sensitivityLevel: .normal,
            browserCategory: .entertainment,
            aiWorkflow: nil,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )

        let presentation = NoxLiveContextPresenter.present(
            signals: [],
            semanticContext: inference,
            contextLabel: "LELEKA - Ridnym (LIVE)"
        )

        #expect(presentation.pulse.first?.text == "Watching LELEKA - Ridnym (LIVE)")
    }

    @Test func privateContextDoesNotUseWindowTitleInPulse() {
        let inference = NoxSemanticInference(
            state: .unknown,
            confidence: 0.9,
            displayPhrase: "Private activity",
            reasons: [],
            fusionLabel: .unknown,
            fusionConfidence: 0.9,
            fusionPhrase: "Private activity",
            sensitivityLevel: .privateContext,
            browserCategory: .privateBrowsing,
            aiWorkflow: nil,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )

        let presentation = NoxLiveContextPresenter.present(
            signals: [],
            semanticContext: inference,
            contextLabel: "Specific private title"
        )

        #expect(presentation.pulse.first?.text == "Private context")
    }

    @Test func currentWritingContextSuppressesStalePassivePulse() {
        let now = Date()
        let inference = NoxSemanticInference(
            state: .writing,
            confidence: 0.75,
            displayPhrase: "Writing",
            reasons: [],
            fusionLabel: .likelyAIAssistedWork,
            fusionConfidence: 0.7,
            fusionPhrase: "AI-assisted work",
            sensitivityLevel: .normal,
            browserCategory: .aiWorkflow,
            aiWorkflow: .promptWriting,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )
        let signals = [
            NoxLiveSignal(
                id: "semantic-old",
                timestamp: now.addingTimeInterval(-20),
                text: "Watching",
                kind: .awareness
            )
        ]

        let presentation = NoxLiveContextPresenter.present(
            signals: signals,
            semanticContext: inference
        )

        #expect(presentation.pulse.map(\.text) == ["Writing"])
    }

    @Test func separatesPulseAndAppTrailDetail() {
        let now = Date()
        let inference = NoxSemanticInference(
            state: .fragmentedInteraction,
            confidence: 0.75,
            displayPhrase: "",
            reasons: [],
            fusionLabel: .likelyAIAssistedWork,
            fusionConfidence: 0.7,
            fusionPhrase: "",
            sensitivityLevel: .normal,
            browserCategory: .aiWorkflow,
            aiWorkflow: .researchHeavy,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )
        let signals = [
            NoxLiveSignal(
                id: "semantic-1",
                timestamp: now,
                text: "Fragmented attention period",
                kind: .awareness
            ),
            NoxLiveSignal(id: "1", timestamp: now, text: "Switched to ChatGPT", kind: .app),
            NoxLiveSignal(id: "2", timestamp: now.addingTimeInterval(-40), text: "Switched to Cursor", kind: .app)
        ]
        let presentation = NoxLiveContextPresenter.present(
            signals: signals,
            semanticContext: inference
        )
        #expect(!presentation.pulse.isEmpty)
        if let trail = presentation.detail.first?.text {
            #expect(trail.contains("→"))
        }
    }
}

struct NoxDaySemanticFramingTests {

    @Test func overviewMentionsFragmentedDay() {
        let blocks: [NoxTimelineBlockItem] = [
            NoxTimelineBlockItem(
                id: "1",
                timestamp: Date(),
                kind: .semanticSpan(
                    NoxSemanticMemorySpan(
                        id: "1",
                        startedAt: Date(),
                        endedAt: Date(),
                        title: "Fragmented attention period",
                        subtitle: "Many apps",
                        interactionStyle: "",
                        semanticState: .fragmentedInteraction,
                        fusionLabel: .unknown,
                        sensitivityLevel: .normal,
                        confidence: 0.6,
                        appNames: [],
                        reasonsJson: nil
                    )
                ),
                title: "Fragmented attention period",
                subtitle: nil,
                detailLine: nil,
                durationText: "22m",
                category: nil,
                markerSymbol: nil
            )
        ]
        let stats = NoxMemoryDayStats(
            periodLabel: "Today",
            totalActiveMs: 3_600_000,
            focusedMs: 600_000,
            fragmentedMs: 2_000_000,
            appSwitchCount: 15,
            longestFocusBlockMs: 0,
            dominantApp: nil,
            dominantCategory: nil
        )
        let overview = NoxDaySemanticFraming.overview(blocks: blocks, stats: stats)
        #expect(overview?.localizedCaseInsensitiveContains("contexts") == true)
    }

    @Test func overviewNeedsSecondFragmentedBlock() {
        let blocks = (0..<2).map { i in
            NoxTimelineBlockItem(
                id: "\(i)",
                timestamp: Date(),
                kind: .semanticSpan(
                    NoxSemanticMemorySpan(
                        id: "\(i)",
                        startedAt: Date(),
                        endedAt: Date(),
                        title: "Fragmented attention period",
                        subtitle: "Many apps",
                        interactionStyle: "",
                        semanticState: .fragmentedInteraction,
                        fusionLabel: .unknown,
                        sensitivityLevel: .normal,
                        confidence: 0.6,
                        appNames: [],
                        reasonsJson: nil
                    )
                ),
                title: "Fragmented attention period",
                subtitle: "Many apps",
                detailLine: nil,
                durationText: "10m",
                category: nil,
                markerSymbol: nil
            )
        }
        let stats = NoxMemoryDayStats(
            periodLabel: "Today",
            totalActiveMs: 3_600_000,
            focusedMs: 600_000,
            fragmentedMs: 2_000_000,
            appSwitchCount: 15,
            longestFocusBlockMs: 0,
            dominantApp: nil,
            dominantCategory: nil
        )
        let overview = NoxDaySemanticFraming.overview(blocks: blocks, stats: stats)
        #expect(overview?.localizedCaseInsensitiveContains("contexts") == true)
    }
}

struct NoxTrustAndAwarenessTests {

    @Test func emotionalSafetyBlocksManipulativeCopy() {
        #expect(!NoxEmotionalSafetyCopy.isAllowed("You were productive yesterday!"))
        #expect(NoxEmotionalSafetyCopy.sanitize("Stay focused on your goals") != "Stay focused on your goals")
    }

    @Test func awarenessLevelRespectsPause() {
        let caps = NoxCapabilityState(
            accessibilityGranted: true,
            screenRecordingGranted: false,
            appAwarenessAvailable: true,
            windowAwarenessAvailable: true,
            interactionSignalsAvailable: true
        )
        var pause = NoxAmbientPauseState.active
        pause.observationPaused = true
        let level = NoxAwarenessPresenter.resolveLevel(
            capabilities: caps,
            memoryReadiness: .ready,
            pauseState: pause
        )
        #expect(level == .minimal)
    }

    @Test func quietModePausesSemanticIngest() {
        var pause = NoxAmbientPauseState.active
        NoxQuietModeEngine.apply(.privateSession, to: &pause)
        #expect(!NoxQuietModeEngine.shouldIngestSemanticMemory(pause))
    }
}

struct NoxReflectiveContinuityTests {

    @Test func morningEngineProducesCalmCopy() {
        let stats = NoxMemoryDayStats(
            periodLabel: "Today",
            totalActiveMs: 600_000,
            focusedMs: 200_000,
            fragmentedMs: 100_000,
            appSwitchCount: 4,
            longestFocusBlockMs: 0,
            dominantApp: "Xcode",
            dominantCategory: nil
        )
        let snapshot = NoxMorningContinuityEngine.buildSnapshot(
            trigger: .morningWindow,
            at: Date(),
            threads: [],
            semanticSpans: [],
            stats: stats,
            focus: nil,
            continuityNote: nil,
            lastShutdownAt: Date().addingTimeInterval(-12 * 3600)
        )
        let summary = NoxMorningSummaryPresenter.present(snapshot: snapshot)
        #expect(summary != nil)
        #expect(summary?.headline.localizedCaseInsensitiveContains("productive") == false)
        #expect(summary?.headline.localizedCaseInsensitiveContains("goal") == false)
    }

    @Test func emergingMemoryNeverUsesContextsAreForming() {
        let span = NoxSemanticMemorySpan(
            id: "s1",
            startedAt: Date().addingTimeInterval(-120),
            endedAt: nil,
            title: "Development context",
            subtitle: "Xcode",
            interactionStyle: "Focused",
            semanticState: .sustainedInteraction,
            fusionLabel: .likelyWorkRelated,
            sensitivityLevel: .normal,
            confidence: 0.5,
            appNames: ["Xcode"],
            reasonsJson: nil
        )
        let result = NoxEmergingMemoryEngine.observe(
            semanticSpans: [],
            openSpan: span,
            threads: [],
            stats: NoxMemoryDayStats(
                periodLabel: "Today",
                totalActiveMs: 120_000,
                focusedMs: 0,
                fragmentedMs: 0,
                appSwitchCount: 2,
                longestFocusBlockMs: 0,
                dominantApp: nil,
                dominantCategory: nil
            ),
            liveSignalCount: 2,
            continuitySeconds: 400
        )
        let copy = NoxEmergingMemoryEngine.primaryCopy(
            maturity: result.maturity,
            observations: result.observations,
            readiness: .building
        )
        #expect(copy.title != "Contexts are forming")
        #expect(!result.observations.isEmpty || result.maturity != .transient)
    }

    @Test func reflectiveSynthesisRespectsCooldown() {
        let recent = Date().addingTimeInterval(-60)
        #expect(NoxReflectiveSynthesisEngine.shouldSynthesize(lastReflectionAt: recent) == false)
        #expect(NoxReflectiveSynthesisEngine.shouldSynthesize(lastReflectionAt: nil) == true)
    }

    @Test func reflectionPresenterDedupesIdenticalText() {
        let now = Date()
        let duplicate = NoxReflectionCandidate(
            id: "a",
            text: "Same observation.",
            detailLine: "Detail A",
            confidence: 0.6,
            createdAt: now,
            sourceSignals: []
        )
        let other = NoxReflectionCandidate(
            id: "b",
            text: "Same observation.",
            detailLine: "Detail B",
            confidence: 0.55,
            createdAt: now.addingTimeInterval(-60),
            sourceSignals: []
        )
        let unique = NoxReflectionCandidate(
            id: "c",
            text: "Different observation.",
            detailLine: "Detail C",
            confidence: 0.54,
            createdAt: now.addingTimeInterval(-120),
            sourceSignals: []
        )
        let distinct = NoxReflectionPresenter.distinct([duplicate, other, unique], limit: 4)
        #expect(distinct.count == 2)
        #expect(distinct.map(\.text).contains("Different observation."))
    }

    @Test func reflectiveSynthesisProducesDistinctStableIds() {
        let input = NoxReflectionInput(
            periodLabel: "Today",
            semanticThemes: ["Development", "Research"],
            continuityResumptions: 3,
            fragmentedSessions: 2,
            dominantArcLabels: ["Creative exploration"],
            resurfacedArcLabels: ["AI-assisted development"],
            recurringThreadTitles: ["AI-assisted development continuity"],
            observationHours: 6,
            hasPriorDayActivity: true,
            behavioralPatternLabels: ["Deep-focus streak"],
            behavioralPatternDetails: ["Sustained focus blocks have been forming locally."],
            temporalRhythmLabels: ["Weekly rhythm"],
            temporalRhythmDetails: ["Work density clusters mid-week."],
            driftObservation: "Less stable rhythms. Recent rhythms have been less stable than usual.",
            lifeStructureLabels: ["Coordination-heavy era"],
            lifeStructureDetails: ["Scheduling and communication may be shaping the week."],
            focusSummary: "fragmented attention",
            weeklyHorizonSnippet: "Development and research alternated across the week with calmer evenings."
        )
        let results = NoxReflectiveSynthesisEngine.synthesize(input: input)
        #expect(results.count >= 2)
        #expect(Set(results.map(\.id)).count == results.count)
        #expect(results.allSatisfy { !$0.detailLine.isEmpty })
        #expect(Set(results.map(\.text)).count == results.count)
    }

    @Test func semanticArcsGroupDevelopmentSpans() {
        let base = Date().addingTimeInterval(-3600)
        let spans = (0..<3).map { index in
            NoxSemanticMemorySpan(
                id: "dev-\(index)",
                startedAt: base.addingTimeInterval(Double(index) * 900),
                endedAt: base.addingTimeInterval(Double(index) * 900 + 600),
                title: "Development context",
                subtitle: "Apps",
                interactionStyle: "",
                semanticState: .sustainedInteraction,
                fusionLabel: .likelyWorkRelated,
                sensitivityLevel: .normal,
                confidence: 0.6,
                appNames: ["Xcode"],
                reasonsJson: nil
            )
        }
        let arcs = NoxSemanticArcEngine.buildArcs(spans: spans, threads: [])
        #expect(!arcs.isEmpty)
        #expect(arcs.contains { $0.arcType == .development })
    }

    @Test func resurfacingOrchestratorLimitsFrequency() {
        let notes = NoxContinuityResurfacingOrchestrator.resurfacingNotes(
            threads: [],
            arcs: [],
            lastShownAt: Date(),
            at: Date()
        )
        #expect(notes.isEmpty)
    }
}

struct NoxTimelineBlockPresenterTests {

    @Test func activitySpanHiddenWhenCoveredBySemanticSpan() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let semantic = NoxSemanticMemorySpan(
            id: "sem-1",
            startedAt: base,
            endedAt: base.addingTimeInterval(3600),
            title: "Development",
            subtitle: "Cursor",
            interactionStyle: "",
            semanticState: .sustainedInteraction,
            fusionLabel: .likelyWorkRelated,
            sensitivityLevel: .normal,
            confidence: 0.7,
            appNames: ["Cursor"],
            reasonsJson: nil
        )
        let activity = NoxActivitySpan(
            id: "act-1",
            startedAt: base.addingTimeInterval(300),
            endedAt: base.addingTimeInterval(900),
            appName: "Cursor",
            bundleId: "com.cursor",
            windowTitle: nil,
            contextLabel: nil,
            category: .development,
            interruptions: 0,
            focusScore: 0.5,
            metadataJson: nil
        )
        let filtered = NoxTimelineActivityDeduper.filter(
            activitySpans: [activity],
            semanticSpans: [semantic],
            at: base.addingTimeInterval(3600)
        )
        #expect(filtered.isEmpty)
    }

    @Test func activityDedupUsesTimeOverlapNotText() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let semantic = NoxSemanticMemorySpan(
            id: "sem-1",
            startedAt: base,
            endedAt: base.addingTimeInterval(600),
            title: "Development",
            subtitle: "Apps",
            interactionStyle: "",
            semanticState: .sustainedInteraction,
            fusionLabel: .likelyWorkRelated,
            sensitivityLevel: .normal,
            confidence: 0.7,
            appNames: ["Xcode"],
            reasonsJson: nil
        )
        let activity = NoxActivitySpan(
            id: "act-1",
            startedAt: base.addingTimeInterval(120),
            endedAt: base.addingTimeInterval(180),
            appName: "Xcode",
            bundleId: "com.apple.dt.Xcode",
            windowTitle: nil,
            contextLabel: nil,
            category: .development,
            interruptions: 0,
            focusScore: 0.5,
            metadataJson: nil
        )
        let intervalA = NoxTimeInterval(start: activity.startedAt, end: activity.endedAt!)
        let intervalB = NoxTimeInterval(start: semantic.startedAt, end: semantic.endedAt!)
        #expect(intervalA.overlaps(intervalB))
        #expect(NoxTimelineActivityDeduper.filter(activitySpans: [activity], semanticSpans: [semantic], at: base.addingTimeInterval(600)).isEmpty)
    }

    @Test func sectionsGroupByLayer() {
        let base = Date()
        let sections = NoxTimelineBlockPresenter.makeSections(
            spans: [
                NoxActivitySpan(
                    id: "a1",
                    startedAt: base,
                    endedAt: base.addingTimeInterval(120),
                    appName: "Safari",
                    bundleId: "com.apple.Safari",
                    windowTitle: nil,
                    contextLabel: nil,
                    category: .research,
                    interruptions: 0,
                    focusScore: 0.2,
                    metadataJson: nil
                )
            ],
            focusBlocks: [],
            interruptions: [],
            semanticSpans: [],
            continuityThreads: []
        )
        #expect(sections.count == 1)
        #expect(sections.first?.layer == .activity)
    }
}

struct NoxMemoryPeriodEmptyCopyTests {

    @Test func yesterdayEmptyCopyIsHistorical() {
        let title = NoxMemoryPeriodEmptyCopy.title(
            period: .yesterday,
            stats: .empty
        )
        let detail = NoxMemoryPeriodEmptyCopy.detail(period: .yesterday)
        #expect(!title.localizedCaseInsensitiveContains("forming"))
        #expect(detail.localizedCaseInsensitiveContains("Historical"))
    }
}

struct NoxConnectorPhase9Tests {

    @Test func calendarClassifierProducesGeneralizedLabels() {
        let profile = NoxCalendarDayProfile(
            eventCount: 6,
            meetingMinutes: 260,
            longestGapMinutes: 25,
            afternoonEventCount: 4,
            eveningEventCount: 2,
            backToBackBlocks: 3,
            hasTravelLikeStructure: false
        )
        let signals = NoxCalendarEventClassifier.generalizedSignals(profile: profile)
        #expect(signals.contains { $0.label.contains("dense") || $0.label.contains("coordination") })
        #expect(signals.allSatisfy { !$0.label.localizedCaseInsensitiveContains("meeting with") })
    }

    @Test func communicationPressureAvoidsInboxLanguage() {
        let cadence = NoxCommunicationCadenceSnapshot(
            communicationMinutes: 95,
            communicationSpanCount: 4,
            burstWindows: 2,
            quietMinutes: 10,
            responseHeavyScore: 0.7
        )
        let result = NoxCommunicationPressureEngine.analyze(
            cadence: cadence,
            stats: NoxMemoryDayStats(
                periodLabel: "Today",
                totalActiveMs: 3600_000,
                focusedMs: 1200_000,
                fragmentedMs: 900_000,
                appSwitchCount: 10,
                longestFocusBlockMs: 1800_000,
                dominantApp: "Mail",
                dominantCategory: .communication
            ),
            focus: nil
        )
        #expect(!result.signals.isEmpty || !result.pressure.isEmpty)
        let combined = result.signals.map(\.label) + result.pressure.map(\.label)
        #expect(combined.allSatisfy { !$0.localizedCaseInsensitiveContains("reply") })
    }

    @Test func interventionRespectsCooldown() {
        let intervention = NoxAmbientInterventionEngine.evaluate(
            transitions: [
                NoxTransitionEvent(
                    id: "t1",
                    kind: .returningAfterAbsence,
                    label: "Returning",
                    confidence: 0.8,
                    observedAt: Date()
                )
            ],
            cadencePatterns: [],
            overloadSignals: [],
            calendarSignals: [],
            lastInterventionAt: Date().addingTimeInterval(-1200)
        )
        #expect(intervention == nil)
    }

    @Test func recoveryCopyIsObservational() {
        let signals = NoxRecoveryInferenceEngine.overloadSignals(
            stats: NoxMemoryDayStats(
                periodLabel: "Today",
                totalActiveMs: 8 * 3600_000,
                focusedMs: 1000_000,
                fragmentedMs: 3 * 3600_000,
                appSwitchCount: 16,
                longestFocusBlockMs: 900_000,
                dominantApp: nil,
                dominantCategory: .development
            ),
            focus: NoxFocusAnalysis(kind: .fragmented, uninterruptedMs: 0, switchCount: 16, continuityScore: 0.2),
            calendarProfile: NoxCalendarDayProfile(
                eventCount: 5,
                meetingMinutes: 200,
                longestGapMinutes: 20,
                afternoonEventCount: 3,
                eveningEventCount: 0,
                backToBackBlocks: 2,
                hasTravelLikeStructure: false
            ),
            pressureSignals: [
                NoxPressureSignal(
                    id: "p1",
                    kind: .calendar,
                    label: "Elevated",
                    level: .elevated,
                    confidence: 0.8,
                    observedAt: Date()
                )
            ]
        )
        #expect(signals.allSatisfy { !$0.label.localizedCaseInsensitiveContains("burnout") })
    }

    @Test @MainActor func connectorOrchestratorHonorsPause() async {
        let store = NoxConnectorSignalStore()
        try? await store.open()
        let snapshot = await NoxConnectorContinuityOrchestrator.refresh(
            preferences: NoxConnectorPreferences(
                calendarEnabled: true,
                communicationPressureEnabled: true,
                continuityEnrichmentPaused: true
            ),
            stats: .empty,
            focus: nil,
            spans: [],
            range: (Date(), Date()),
            storedPatterns: [],
            recentDailyDensity: [],
            previousFocusKind: nil,
            observationGapHours: 0,
            lastInterventionAt: nil,
            signalStore: store
        )
        #expect(snapshot == .empty)
    }
}

struct NoxAmbientUtilityCalibrationPhase11_5Tests {

    @Test func notificationCalibrationBlocksHighFatigue() {
        let allows = NoxNotificationCalibrationEngine.calibratedAllows(
            candidate: NoxAmbientNotificationCandidate(
                id: "n1",
                kind: "unfinished_continuity",
                title: "Nox",
                body: "A thread resurfaced.",
                confidence: 0.6
            ),
            fatigue: 0.8,
            trustScore: 0.5,
            interruptionCost: 0.4,
            baseAllows: true,
            preferSilence: false
        )
        #expect(!allows)
    }

    @Test func silenceRefinementDuringPassiveCollapse() {
        let quality = NoxRecoveryQualityModel(
            kind: .passiveCollapse,
            suppressResurfacing: true,
            preferSilence: true,
            allowGentleContinuity: false,
            confidence: 0.65
        )
        #expect(NoxSilenceRefinementEngine.preferSilence(
            basePreferSilence: false,
            recoveryQuality: quality,
            interruptionCost: 0.5,
            receptiveness: NoxInterventionReceptiveness(
                score: 0.5,
                interruptionSensitive: false,
                deepFocusStable: false,
                recoveryOpen: false,
                fragmented: false,
                passiveDecompression: true
            ),
            calmness: .balanced,
            globalRestraint: 0.6
        ))
    }

    @Test func gravityEvolutionWeakensFadingThreads() {
        let thread = NoxContinuityThread(
            id: "t1",
            semanticType: .aiDevelopment,
            title: "Alpha continuity",
            dominantApps: [],
            dominantCategories: [],
            dominantDomains: [],
            continuitySignature: NoxContinuitySignature(
                ecosystemKey: "a",
                semanticType: .aiDevelopment,
                appTokens: [],
                semanticState: .writing,
                fusionLabel: .likelyAIAssistedWork,
                interactionProfile: "steady",
                densityProfile: "moderate"
            ),
            firstSeenAt: Date().addingTimeInterval(-20 * 86_400),
            lastSeenAt: Date(),
            totalActiveDurationMs: 1_000_000,
            totalSessions: 2,
            totalResumptions: 1,
            continuityStrength: 0.35,
            recurrenceStrength: 0.3,
            interruptionPattern: "steady",
            currentStatus: .paused,
            recentMemoryIds: [],
            linkedSpanIds: [],
            linkedSessionIds: [],
            supportingSignals: [],
            confidence: 0.5,
            lastResumedAt: nil,
            temporalPatterns: [],
            decayState: .fading,
            sensitivityLevel: .normal
        )
        let evolved = NoxContinuityGravityEvolutionEngine.evolve(
            threads: [thread],
            arcs: [],
            stored: ["t1": 0.7]
        )
        #expect((evolved["t1"] ?? 1) < 0.7)
    }

    @Test func trustTrackerIncreasesFatigueOnPoorTiming() {
        var trust = NoxAmbientTrustState.initial
        NoxNotificationTrustTracker.recordRefresh(
            trust: &trust,
            notificationDelivered: true,
            notificationSuppressed: false,
            preferSilence: false,
            interruptionCost: 0.8,
            poorTiming: true
        )
        #expect(trust.notificationFatigue > 0.1)
        #expect(trust.poorTimingEventCount >= 1)
    }
}

struct NoxAmbientUtilityPhase11Tests {

    @Test func calmnessReducesReflectionDuringFragmentation() {
        let calmness = NoxAdaptiveCalmnessEngine.profile(
            receptiveness: NoxInterventionReceptiveness(
                score: 0.35,
                interruptionSensitive: true,
                deepFocusStable: false,
                recoveryOpen: false,
                fragmented: true,
                passiveDecompression: false
            ),
            decompression: NoxDecompressionState(
                inDecompression: false,
                recoveryWindowOpen: false,
                passiveCollapseLoop: false,
                overloadAfterCoordination: false,
                confidence: 0.4
            ),
            behavioral: .empty,
            connectorSnapshot: .empty
        )
        #expect(calmness.reflectionDensity < 0.7)
        #expect(calmness.notificationProbability < 0.4)
    }

    @Test func silencePreferredDuringDecompression() {
        let decompression = NoxDecompressionState(
            inDecompression: true,
            recoveryWindowOpen: false,
            passiveCollapseLoop: true,
            overloadAfterCoordination: false,
            confidence: 0.65
        )
        let receptiveness = NoxInterventionReceptivenessModel.evaluate(
            focus: nil,
            stats: .empty,
            behavioral: .empty,
            decompression: decompression
        )
        let calmness = NoxAdaptiveCalmnessEngine.profile(
            receptiveness: receptiveness,
            decompression: decompression,
            behavioral: .empty,
            connectorSnapshot: .empty
        )
        #expect(NoxAmbientSilenceEngine.shouldPreferSilence(
            receptiveness: receptiveness,
            decompression: decompression,
            calmness: calmness,
            behavioral: .empty
        ))
    }

    @Test func notificationCopyAvoidsCoachingLanguage() {
        let candidate = NoxNotificationRelevanceModel.candidate(
            unfinished: [
                NoxUnfinishedContinuityCandidate(
                    id: "u1",
                    label: "Development",
                    detail: "Keeps returning.",
                    persistenceScore: 0.7,
                    resumptions: 3
                )
            ],
            behavioral: .empty,
            receptiveness: NoxInterventionReceptiveness(
                score: 0.6,
                interruptionSensitive: false,
                deepFocusStable: false,
                recoveryOpen: true,
                fragmented: false,
                passiveDecompression: false
            ),
            calmness: .balanced,
            preferSilence: false,
            fragmentedReductionActive: false
        )
        if let candidate {
            let combined = "\(candidate.title) \(candidate.body)".lowercased()
            #expect(!combined.contains("take a break"))
            #expect(!combined.contains("don't forget"))
            #expect(!combined.contains("stay focused"))
        }
    }

    @Test @MainActor func utilityOrchestratorHonorsPause() async {
        let snapshot = NoxAmbientUtilityOrchestrator.refresh(
            paused: true,
            preferences: .default,
            stats: .empty,
            focus: nil,
            threads: [],
            arcs: [],
            connectorSnapshot: .empty,
            behavioralSnapshot: .empty,
            proposedIntervention: nil,
            lastNudgeAt: nil,
            ambientState: .empty
        )
        #expect(snapshot == .empty)
    }
}

struct NoxContinuityMaturityPhase10_5Tests {

    @Test func languageSoftenerRemovesEngineVocabulary() {
        let raw = "Fragmented context period alongside oscillating cadence detected."
        let softened = NoxReflectiveLanguageSoftener.soften(raw)
        #expect(!softened.localizedCaseInsensitiveContains("oscillating cadence"))
        #expect(!softened.localizedCaseInsensitiveContains("detected"))
    }

    @Test func reflectionSuppressionLimitsMarginalReflections() {
        let context = NoxContinuityMaturityContext.build(
            input: .empty,
            focus: nil,
            behavioral: .empty,
            connectorSnapshot: .empty
        )
        let matured = NoxMaturedReflection(
            candidate: NoxReflectionCandidate(
                id: "reflection-focus-rhythm",
                text: "Today leaned toward fragmented attention.",
                detailLine: "From focus blocks.",
                confidence: 0.53,
                createdAt: Date(),
                sourceSignals: []
            ),
            gravity: 0.4,
            salience: .quiet
        )
        #expect(NoxReflectionSuppressionEngine.shouldSuppress(
            matured: matured,
            stored: [],
            context: context
        ))
    }

    @Test func naturalizationGroundsTemporalPhrasing() {
        let candidate = NoxReflectionCandidate(
            id: "reflection-fragmentation",
            text: "Attention split across contexts.",
            detailLine: "From focus analysis.",
            confidence: 0.58,
            createdAt: Date(),
            sourceSignals: []
        )
        let input = NoxReflectionInput(
            periodLabel: "Today",
            semanticThemes: [],
            continuityResumptions: 0,
            fragmentedSessions: 3,
            dominantArcLabels: [],
            resurfacedArcLabels: [],
            recurringThreadTitles: [],
            observationHours: 4,
            hasPriorDayActivity: false,
            behavioralPatternLabels: [],
            behavioralPatternDetails: [],
            temporalRhythmLabels: [],
            temporalRhythmDetails: [],
            driftObservation: nil,
            lifeStructureLabels: [],
            lifeStructureDetails: [],
            focusSummary: "fragmented attention",
            weeklyHorizonSnippet: nil
        )
        let naturalized = NoxReflectionNaturalizationEngine.naturalize(
            candidate,
            input: input,
            salience: .fragile
        )
        #expect(naturalized.text.lowercased().contains("recent"))
    }

    @Test func maturityOrchestratorReturnsAtMostThreeReflections() {
        let input = NoxReflectionInput(
            periodLabel: "Today",
            semanticThemes: ["Development", "Research"],
            continuityResumptions: 4,
            fragmentedSessions: 3,
            dominantArcLabels: ["AI-assisted development"],
            resurfacedArcLabels: ["AI-assisted development"],
            recurringThreadTitles: ["AI-assisted development continuity"],
            observationHours: 8,
            hasPriorDayActivity: true,
            behavioralPatternLabels: ["Deep-focus streak"],
            behavioralPatternDetails: ["Sustained focus blocks have been forming locally."],
            temporalRhythmLabels: ["Weekly rhythm"],
            temporalRhythmDetails: ["Work density clusters mid-week."],
            driftObservation: "Less stable rhythms. Recent rhythms have been less stable than usual.",
            lifeStructureLabels: ["Coordination-heavy era"],
            lifeStructureDetails: ["Scheduling density may be shaping the week."],
            focusSummary: "fragmented attention",
            weeklyHorizonSnippet: "Development and research alternated with quieter evenings across the week."
        )
        let raw = NoxReflectiveSynthesisEngine.synthesize(input: input)
        let matured = NoxContinuityMaturityOrchestrator.matureReflections(
            raw,
            input: input,
            stored: [],
            threads: [],
            arcs: [],
            behavioral: .empty,
            focus: nil,
            connectorSnapshot: .empty
        )
        #expect(matured.count <= 3)
        #expect(matured.allSatisfy { !$0.text.localizedCaseInsensitiveContains("oscillating cadence") })
    }
}

struct NoxBehavioralIntelligencePhase10Tests {

    @Test func patternEngineGatesLowConfidence() {
        let signatures = NoxBehavioralPatternEngine.detect(
            stats: .empty,
            focus: nil,
            spans: [],
            connectorCadence: [],
            recentDailyDensity: [],
            weeklyRollups: []
        )
        #expect(signatures.allSatisfy { $0.confidence >= NoxPatternConfidenceModel.minimumDisplay })
    }

    @Test func driftCopyAvoidsAlarmLanguage() {
        let drift = NoxBehavioralDriftEngine.detect(
            recentDailyDensity: [0.7, 0.68, 0.65, 0.2, 0.18, 0.15],
            stats: NoxMemoryDayStats(
                periodLabel: "Today",
                totalActiveMs: 20 * 60_000,
                focusedMs: 5 * 60_000,
                fragmentedMs: 10 * 60_000,
                appSwitchCount: 4,
                longestFocusBlockMs: 600_000,
                dominantApp: nil,
                dominantCategory: .passive
            ),
            focus: nil,
            signatures: []
        )
        if let drift {
            let combined = "\(drift.label) \(drift.detail)".lowercased()
            #expect(!combined.contains("wrong"))
            #expect(!combined.contains("burnout"))
            #expect(!combined.contains("failing"))
        }
    }

    @Test func adaptiveInterventionSuppressesDuringDeepFocus() {
        let orchestration = NoxAmbientOrchestrationContext(
            signals: [
                NoxOrchestrationSignal(
                    id: "focus",
                    kind: .deepFocusStability,
                    level: 0.85,
                    note: "stable"
                )
            ],
            generatedAt: Date()
        )
        let base = NoxAmbientIntervention(
            id: "frag",
            label: "Fragmented day",
            detail: "Observed locally.",
            kind: .fragmentedDayAck,
            observedAt: Date()
        )
        let connector = NoxConnectorContinuitySnapshot(
            generalizedSignals: [],
            pressureSignals: [],
            cadencePatterns: [],
            transitions: [],
            overloadSignals: [],
            enrichmentNotes: [],
            explainability: .empty,
            intervention: base
        )
        let result = NoxAdaptiveInterventionTimingEngine.evaluate(
            connectorSnapshot: connector,
            orchestration: orchestration,
            signatures: [],
            drift: nil,
            lastInterventionAt: Date().addingTimeInterval(-7 * 3600)
        )
        #expect(result == nil)
    }

    @Test @MainActor func behavioralOrchestratorHonorsPause() async {
        let store = NoxBehavioralIntelligenceSignalStore()
        try? await store.open()
        let snapshot = await NoxBehavioralIntelligenceOrchestrator.refresh(
            paused: true,
            connectorSnapshot: .empty,
            stats: .empty,
            focus: nil,
            spans: [],
            threads: [],
            arcs: [],
            weeklyRollups: [],
            monthlyRollups: [],
            recentDailyDensity: [],
            lastInterventionAt: nil,
            signalStore: store
        )
        #expect(snapshot == .empty)
    }

    @Test func memoryPrioritizerOrdersByAdaptiveWeight() {
        func thread(
            id: String,
            title: String,
            strength: Double,
            recurrence: Double,
            resumptions: Int
        ) -> NoxContinuityThread {
            NoxContinuityThread(
                id: id,
                semanticType: .aiDevelopment,
                title: title,
                dominantApps: [],
                dominantCategories: [],
                dominantDomains: [],
                continuitySignature: NoxContinuitySignature(
                    ecosystemKey: id,
                    semanticType: .aiDevelopment,
                    appTokens: [],
                    semanticState: .writing,
                    fusionLabel: .likelyAIAssistedWork,
                    interactionProfile: "steady",
                    densityProfile: "moderate"
                ),
                firstSeenAt: Date(),
                lastSeenAt: Date(),
                totalActiveDurationMs: 3_600_000,
                totalSessions: 2,
                totalResumptions: resumptions,
                continuityStrength: strength,
                recurrenceStrength: recurrence,
                interruptionPattern: "steady",
                currentStatus: .active,
                recentMemoryIds: [],
                linkedSpanIds: [],
                linkedSessionIds: [],
                supportingSignals: [],
                confidence: 0.7,
                lastResumedAt: resumptions > 0 ? Date() : nil,
                temporalPatterns: [],
                decayState: .active,
                sensitivityLevel: .normal
            )
        }
        let threads = [
            thread(id: "a", title: "Alpha", strength: 0.4, recurrence: 0.2, resumptions: 0),
            thread(id: "b", title: "Beta", strength: 0.9, recurrence: 0.8, resumptions: 3)
        ]
        let weights = NoxAdaptiveContinuityModel.weights(
            threads: threads,
            arcs: [],
            signatures: []
        )
        let result = NoxContextualMemoryPrioritizer.prioritize(
            threads: threads,
            arcs: [],
            weights: weights,
            signatures: [],
            lifeStructures: [],
            drift: nil,
            existingNotes: []
        )
        #expect(result.threadIds.first == "b")
    }
}
