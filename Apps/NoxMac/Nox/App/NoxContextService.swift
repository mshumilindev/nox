import Foundation
import AppKit
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
import NoxShrineCore

@MainActor
final class NoxContextService {
    private let permissionService = NoxPermissionService()
    private let presenceEngine = NoxPresenceEngine()
    private let presenceStabilizer = NoxPresenceStabilizer()
    private let timelineStore = NoxTimelineStore()
    private let memoryCoordinator = NoxMemoryCoordinator()
    private let ambientStateStore = NoxAmbientStateStore()
    private let sessionStore = NoxSessionStore()
    private let interactionCollector = NoxInteractionSignalCollector()
    private let metricsAggregator = NoxInteractionMetricsAggregator()
    private let semanticEngine = NoxSemanticInferenceEngine()
    let liveBuffer = NoxLiveSignalBuffer(capacity: 24)
    private let metadataExtractor = NoxMetadataExtractor()
    private let domainClassifier = NoxDomainClassifier()
    private var contextPipeline = NoxContextAcquisitionPipeline()
    private let contextHeartbeat = NoxContextHeartbeat()
    private var semanticCadence = NoxSemanticEvaluationCadence()
    private var latestContextEvidence: NoxContextEvidence?

    private var sessionDetector = NoxSessionDetector()
    var signalTracker = NoxActivitySignalTracker()
    private var engagementStabilizer = NoxEngagementStabilizer()
    private var latestEngagementState: NoxEngagementState?
    private var lastDurableSnapshot: NoxActivitySnapshot?
    private var lastWanderingIngestAt: Date?
    private var recentBundleIds: [String] = []
    private var latestSemanticInference = NoxSemanticInference.hidden
    private var lastSnapshot: NoxActivitySnapshot?
    private var lastActiveSignalByBundle: [String: Date] = [:]
    private var capabilities = NoxCapabilityState.unavailable
    private var permissionState = NoxPermissionState.limited
    var latestFocusAnalysis: NoxFocusAnalysis?
    private var memoryReloadTask: Task<Void, Never>?
    private var semanticEvaluationTask: Task<Void, Never>?
    var continuityNote: String?
    var ambientState: NoxAmbientState = .empty
    var preferences = NoxAmbientPreferences.default
    private let preferencesStore = NoxPreferencesStore()
    private lazy var memoryControl = NoxMemoryControlCoordinator(
        memoryCoordinator: memoryCoordinator,
        timelineStore: timelineStore
    )
    private let connectorSignalStore = NoxConnectorSignalStore()
    private let behavioralSignalStore = NoxBehavioralIntelligenceSignalStore()
    private lazy var observatoryProvider = NoxObservatoryDataProvider(
        timelineStore: timelineStore,
        memoryCoordinator: memoryCoordinator
    )
    private lazy var connectorControl = NoxConnectorControlCoordinator(
        signalStore: connectorSignalStore,
        behavioralSignalStore: behavioralSignalStore
    )
    private let retentionPolicy = NoxMemoryRetentionPolicy.default
    weak var environment: AppEnvironment?
    private let eventPipeline = NoxContextEventPipeline()
    private let observationPipeline = NoxContextObservationPipeline()

    private lazy var memoryPipeline = NoxContextMemoryPipeline(
        memoryCoordinator: memoryCoordinator,
        observatoryProvider: observatoryProvider,
        connectorSignalStore: connectorSignalStore,
        behavioralSignalStore: behavioralSignalStore,
        ambientStateStore: ambientStateStore,
        host: self
    )

    func bind(environment: AppEnvironment) {
        self.environment = environment
        NoxLifecycleCoordinator.contextService = self
    }

    func start() async {
        refreshPermissionState(force: true)

        liveBuffer.prepend(NoxLiveSignalPresenter.observing())
        publishAwarenessLiveSignal()
        publishLiveSignals()

        do {
            try await timelineStore.open()
            try await memoryCoordinator.open()
            try await ambientStateStore.open()
            try await preferencesStore.open()
            try await sessionStore.open()
            try await connectorSignalStore.open()
            try await behavioralSignalStore.open()
            preferences = (try? await preferencesStore.loadPreferences()) ?? .default
            environment?.preferences = preferences
            environment?.syncDashboardWindowFrame(animated: false)
            await hydrateFromPersistence()
            scheduleMemoryMaintenance()
        } catch {
            environment?.timelineEvents = []
            environment?.galaxyTimelineSections = []
            environment?.deepSpaceTimelineSections = []
            environment?.deepSpaceEntries = []
            environment?.memoryReadiness = .observing
        }

        eventPipeline.startEventHandling { [weak self] event in
            await self?.handle(event)
        }

        observationPipeline.start(
            publishEvent: { [weak self] event in
                self?.eventPipeline.publish(event)
            },
            ingestSnapshot: { [weak self] snapshot in
                await self?.ingestSnapshot(snapshot)
            }
        )

        startPermissionPolling()
        startInteractionSampling()
        startSemanticHeartbeat()
        startMaintenanceLoop()
    }

    func stop() {
        observationPipeline.stop()
        eventPipeline.stop()
        memoryReloadTask?.cancel()
        semanticEvaluationTask?.cancel()
    }

    func checkpointBeforeTerminate() async {
        guard let environment else { return }

        if let stopped = NoxCaffeinateController.shared.stop() {
            ambientState.systemState.caffeinateSession = stopped
        }

        try? await memoryCoordinator.checkpointOpenSpan(at: Date())

        if let session = sessionDetector.exportCurrentSession() {
            try? await sessionStore.upsert(session)
        }

        var ambient = (try? await ambientStateStore.load()) ?? .empty
        ambient.lastPresence = environment.presence.rawValue
        ambient.lastActiveAppName = environment.activeAppName
        ambient.lastActiveBundleId = environment.activeBundleId
        ambient.lastActiveWindowTitle = environment.activeWindowTitle
        ambient.lastShutdownAt = Date()
        ambient.recentBundleIds = recentBundleIds
        let exported = signalTracker.exportPersisted()
        ambient.observationStartedAt = exported.firstSignalAt ?? ambient.observationStartedAt
        try? await ambientStateStore.save(ambient)
        try? await ambientStateStore.saveSignalTracker(exported)
    }

    func updatePreferences(_ preferences: NoxAmbientPreferences) async {
        self.preferences = preferences
        environment?.preferences = preferences
        try? await preferencesStore.savePreferences(preferences)
        refreshAwarenessSnapshot()
        recalculatePresence()
    }

    func clearRecentMemory() async {
        _ = try? await memoryControl.clearRecentMemory()
        await reloadMemoryView()
    }

    func clearSemanticContinuity() async {
        _ = try? await memoryControl.clearSemanticContinuity()
        await reloadMemoryView()
    }

    func reloadMemoryView() async {
        await memoryPipeline.reloadMemoryView()
    }

    func refreshPermissionState() {
        refreshPermissionState(force: false)
    }

    func refreshObservatory(range: NoxObservatoryTimeRange? = nil) async {
        guard let environment else { return }
        let selected = range ?? environment.observatoryRange
        environment.observatorySnapshot = await observatoryProvider.snapshot(
            range: selected,
            behavioralSnapshot: environment.behavioralSnapshot,
            utilitySnapshot: environment.ambientUtilitySnapshot,
            memoryEvolutionSnapshot: environment.memoryEvolutionSnapshot,
            connectorSnapshot: environment.connectorSnapshot
        )
    }

    func performanceDiagnosticsSnapshot() -> NoxPerformanceDiagnosticsSnapshot {
        eventPipeline.diagnosticsSnapshot(
            panelOpen: NoxAppRuntime.panelState.isDashboardOpen,
            presencePageActive: NoxAppRuntime.presenceMesh.isPresencePageActive,
            liveSignalBufferSize: liveBuffer.signals.count,
            recentBundleBufferSize: recentBundleIds.count
        )
    }

    func requestAccessibilityAccess() {
        permissionService.requestAccessibilityPrompt()
        refreshPermissionState(force: true)
    }

    private func refreshPermissionState(force: Bool) {
        let base = permissionService.currentState()
        let tierChanged = base.capabilities.awarenessTier != capabilities.awarenessTier

        guard force ||
                base.accessibilityGranted != permissionState.accessibilityGranted ||
                base.screenRecordingGranted != permissionState.screenRecordingGranted else {
            capabilities = runtimeCapabilities(from: base.capabilities)
            return
        }

        capabilities = runtimeCapabilities(from: base.capabilities)
        observationPipeline.refreshAccessibilityBridge()
        permissionState = NoxPermissionState(
            accessibilityGranted: base.accessibilityGranted,
            screenRecordingGranted: base.screenRecordingGranted,
            canReadAppContext: base.canReadAppContext,
            canReadWindowTitle: base.canReadWindowTitle,
            mode: base.mode,
            capabilities: capabilities
        )
        applyPermissionStateToEnvironment()

        liveBuffer.reconcile(capabilities: capabilities)
        publishAwarenessLiveSignal()

        if tierChanged {
            presenceStabilizer.reset(to: presenceEngine.evaluate(context: makePresenceContext()))
        }

        publishLiveSignals()

        eventPipeline.publish(
            NoxEvent(
                type: .permissionChanged,
                payload: .permission(
                    PermissionPayload(
                        mode: base.mode.rawValue,
                        accessibilityGranted: base.accessibilityGranted,
                        screenRecordingGranted: base.screenRecordingGranted
                    )
                )
            )
        )
        recalculatePresence()
    }

    private func publishAwarenessLiveSignal() {
        switch capabilities.awarenessTier {
        case .full:
            break
        case .appOnly:
            liveBuffer.prepend(NoxLiveSignalPresenter.appLevelAwareness())
        case .unavailable:
            liveBuffer.prepend(NoxLiveSignalPresenter.limitedMode())
        }
    }

    private func startPermissionPolling() {
        eventPipeline.startPermissionPolling { [weak self] in
            self?.refreshPermissionState(force: false)
        }
    }

    private func startInteractionSampling() {
        eventPipeline.startInteractionSampling { [weak self] publish in
            self?.interactionCollector.sample { event in
                publish(event)
            }
        }
    }

    private func startSemanticHeartbeat() {
        eventPipeline.startSemanticHeartbeat { [weak self] in
            guard let self, let snapshot = self.lastSnapshot else { return }
            if NoxSelfExclusion.shouldIgnore(snapshot: snapshot) { return }
            let evidence = self.evaluateContext(for: snapshot, resetDominance: false)
            guard self.contextHeartbeat.shouldEvaluate(snapshot: snapshot, evidence: evidence) else {
                return
            }
            self.publishContextLabel(from: evidence, snapshot: snapshot)
            await self.evaluateSemanticsIfNeeded(for: snapshot, force: false, at: snapshot.capturedAt)
        }
    }

    private func handle(_ event: NoxEvent) async {
        if NoxSelfExclusion.shouldIgnore(event: event) { return }

        ingestInteractionEvent(event)
        appendLiveSignal(from: event)
        processSignals(for: event)
        let immediateSemantic = event.type == .windowChanged || event.type == .appChanged
        if immediateSemantic {
            contextHeartbeat.markContextShift()
            NoxSemanticLiveSignalPresenter.reset()
            if let snapshot = lastSnapshot {
                let evidence = evaluateContext(
                    for: snapshot,
                    resetDominance: event.type == .appChanged
                )
                publishContextLabel(from: evidence, snapshot: snapshot, force: true)
            }
        }
        scheduleSemanticEvaluation(immediate: immediateSemantic)
        recalculatePresence()

        var shouldPersist = true
        if event.type == .appChanged, case .appChanged(let payload) = event.payload {
            let skip = (try? await timelineStore.shouldSkipDuplicate(
                appChanged: payload.bundleId,
                within: 3
            )) ?? false
            shouldPersist = !skip
        }

        if shouldPersist,
           shouldPersistToTimeline(event),
           NoxQuietModeEngine.shouldIngestTimeline(preferences.pauseState) {
            await persist(event)
        }

        if event.type == .sessionStarted || event.type == .sessionEnded {
            await persistSession(from: event)
        } else if sessionDetector.exportCurrentSession() != nil {
            await persistActiveSessionIfNeeded()
        }

        scheduleMemoryReload()
    }

    private func shouldPersistToTimeline(_ event: NoxEvent) -> Bool {
        if event.type == .appChanged || event.type == .windowChanged {
            return false
        }
        return !NoxForbiddenMemoryContent.mustNotPersistToWarmTimeline(eventType: event.type)
    }

    private func persist(_ event: NoxEvent) async {
        do {
            try await timelineStore.insertEvent(from: event)
            let records = try await timelineStore.getRecentEvents(limit: 50)
            environment?.timelineEvents = records
            _ = try? await timelineStore.pruneOldEvents(olderThan: retentionPolicy.warmTimelineDays)
        } catch {
            // Keep UI responsive if persistence fails.
        }
    }

    private func ingestSnapshot(_ snapshot: NoxActivitySnapshot) async {
        if NoxSelfExclusion.shouldIgnore(snapshot: snapshot) {
            applyIdleOnly(from: snapshot)
            return
        }

        let previous = lastSnapshot
        let resetDominance = previous?.bundleId != snapshot.bundleId
        let titleChanged = previous?.windowTitle != snapshot.windowTitle
        let documentURLChanged = previous?.documentURL != snapshot.documentURL
        let contextSurfaceChanged = resetDominance || titleChanged || documentURLChanged
        if resetDominance {
            contextHeartbeat.reset()
            semanticCadence.reset()
            metricsAggregator.resetForContextShift(at: snapshot.capturedAt)
            NoxSemanticLiveSignalPresenter.reset()
        } else if contextSurfaceChanged {
            contextHeartbeat.markContextShift()
            metricsAggregator.resetForContextShift(at: snapshot.capturedAt)
        }
        let contextEvidence = evaluateContext(for: snapshot, resetDominance: resetDominance)
        if shouldTreatAsPassivePlayback(
            evidence: contextEvidence,
            snapshot: snapshot
        ) {
            metricsAggregator.applyPassivePlaybackMode()
        }
        let engagement = engagementStabilizer.ingest(
            snapshot: snapshot,
            metrics: metricsAggregator.snapshot(at: snapshot.capturedAt)
        )
        latestEngagementState = engagement.state
        appendLiveSignalsFromSnapshot(snapshot, previous: previous, evidence: contextEvidence)
        if engagement.becameHard {
            signalTracker.recordSnapshot(snapshot)
        }

        lastSnapshot = snapshot
        environment?.activeAppName = snapshot.appName
        environment?.activeBundleId = snapshot.bundleId
        environment?.activeWindowTitle = snapshot.windowTitle
        publishContextLabel(from: contextEvidence, snapshot: snapshot, force: contextSurfaceChanged)
        environment?.idleSeconds = snapshot.idleSeconds
        environment?.isUserIdle = snapshot.isUserIdle

        let isProductive = NoxPresenceRules.isProductivityApp(
            bundleId: snapshot.bundleId,
            windowTitle: snapshot.windowTitle
        )
        if engagement.state.isHardStabilized {
            if engagement.becameHard {
                sessionDetector.recordAppSwitch()
            }
            _ = sessionDetector.ingest(snapshot: snapshot, isProductive: isProductive) { [weak self] event in
                Task { @MainActor in
                    self?.eventPipeline.publish(event)
                }
            }
            await persistActiveSessionIfNeeded()
        }
        environment?.sessionSummary = sessionDetector.currentSession?.summaryLine
        if engagement.becameHard {
            trackRecentBundle(snapshot.bundleId)
        }
        await evaluateSemanticsIfNeeded(
            for: snapshot,
            force: contextSurfaceChanged || engagement.becameHard,
            at: snapshot.capturedAt
        )
        recalculatePresence()

        if NoxQuietModeEngine.shouldIngestTimeline(preferences.pauseState) {
            Task {
                if engagement.becameHard {
                    let durableSnapshot = stabilizedSnapshot(from: snapshot, state: engagement.state)
                    if let durable = lastDurableSnapshot, durable.bundleId != durableSnapshot.bundleId {
                        try? await memoryCoordinator.ingestAppChange(from: durable, to: durableSnapshot)
                    } else {
                        try? await memoryCoordinator.ingestSnapshot(durableSnapshot)
                    }
                    lastDurableSnapshot = durableSnapshot
                } else if let wandering = engagement.wanderingState,
                          shouldIngestWandering(at: wandering.observedAt) {
                    try? await memoryCoordinator.ingestSnapshot(
                        wanderingSnapshot(from: wandering)
                    )
                }
                await reloadMemoryViewIfDashboardOpen()
            }
        }
    }

    private func stabilizedSnapshot(
        from snapshot: NoxActivitySnapshot,
        state: NoxEngagementState
    ) -> NoxActivitySnapshot {
        NoxActivitySnapshot(
            appName: snapshot.appName,
            bundleId: snapshot.bundleId,
            windowTitle: snapshot.windowTitle,
            documentURL: snapshot.documentURL,
            processId: snapshot.processId,
            idleSeconds: snapshot.idleSeconds,
            isUserIdle: snapshot.isUserIdle,
            capturedAt: state.foregroundStartedAt
        )
    }

    private func appendLiveSignal(from event: NoxEvent) {
        if NoxSelfExclusion.shouldIgnore(event: event) { return }
        guard let signal = NoxLiveSignalPresenter.from(event: event) else { return }
        liveBuffer.prepend(signal)
        publishLiveSignals()
    }

    private func appendLiveSignalsFromSnapshot(
        _ snapshot: NoxActivitySnapshot,
        previous: NoxActivitySnapshot?,
        evidence: NoxContextEvidence
    ) {
        if NoxSelfExclusion.shouldIgnore(snapshot: snapshot) { return }

        if let previous, previous.bundleId != snapshot.bundleId {
            // App switch live lines come from app.changed events.
        } else if previous == nil {
            // Initial app line comes from the first app.changed event.
        }

        publishLiveSignals()
    }

    private func hydrateLiveFromRecentEvents() {
        guard let records = environment?.timelineEvents, !records.isEmpty else { return }
        let hydrated = records.prefix(8).reversed().compactMap { record -> NoxLiveSignal? in
            guard !NoxSelfExclusion.shouldIgnore(record: record) else { return nil }
            guard record.type.contains("app.") ||
                    record.type.contains("idle") ||
                    record.type.contains("session") ||
                    record.type.contains("permission") else {
                return nil
            }
            return NoxLiveSignal(
                id: "live-\(record.id)",
                timestamp: record.timestamp,
                text: record.displayText,
                kind: .app
            )
        }
        liveBuffer.prependUniqueTexts(Array(hydrated))
        liveBuffer.reconcile(capabilities: capabilities)
        publishLiveSignals()
    }

    private func publishLiveSignals() {
        environment?.setLiveSignalsIfChanged(liveBuffer.visibleSignals(capabilities: capabilities))
        syncDerivedEnvironmentState(memoryReadiness: environment?.memoryReadiness ?? .observing)
    }

    private func scheduleMemoryReload() {
        guard NoxAppRuntime.panelState.isDashboardOpen else { return }
        memoryReloadTask?.cancel()
        memoryReloadTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            await reloadMemoryView()
        }
    }

    private func reloadMemoryViewIfDashboardOpen() async {
        guard NoxAppRuntime.panelState.isDashboardOpen else { return }
        await reloadMemoryView()
    }

    private func processSignals(for event: NoxEvent) {
        switch event.payload {
        case .appChanged(let payload):
            guard !NoxSelfExclusion.isExcluded(bundleId: payload.bundleId, appName: payload.appName) else {
                return
            }
            environment?.activeAppName = payload.appName
            environment?.activeBundleId = payload.bundleId
            environment?.activeWindowTitle = payload.windowTitle
        case .windowChanged(let payload):
            guard !NoxSelfExclusion.isExcluded(bundleId: payload.bundleId, appName: payload.appName) else {
                return
            }
            environment?.activeWindowTitle = payload.windowTitle
        case .idle(let payload):
            environment?.idleSeconds = payload.idleSeconds
            environment?.isUserIdle = event.type == .userIdleStarted
            if event.type == .userIdleEnded {
                publishLiveSignals()
            }
        default:
            break
        }
    }

    func recalculatePresence() {
        guard let environment else { return }

        let raw = presenceEngine.evaluate(context: makePresenceContext())
        let stabilized = presenceStabilizer.resolve(proposed: raw)
        environment.sessionSummary = sessionDetector.currentSession?.summaryLine

        let adjusted = NoxQuietModeEngine.presenceCeiling(preferences.pauseState, base: stabilized)
        guard adjusted != environment.presence else { return }

        let previous = environment.presence
        environment.presence = adjusted
        Task {
            await persist(
                NoxEvent(
                    type: .presenceChanged,
                    payload: .presence(
                        PresencePayload(previous: previous.rawValue, current: stabilized.rawValue)
                    )
                )
            )
        }
    }

    private func makePresenceContext() -> NoxPresenceContext {
        let snapshot = lastSnapshot
        return NoxPresenceContext(
            capabilities: capabilities,
            isUserIdle: snapshot?.isUserIdle ?? environment?.isUserIdle ?? false,
            idleSeconds: snapshot?.idleSeconds ?? environment?.idleSeconds ?? 0,
            currentBundleId: snapshot?.bundleId ?? environment?.activeBundleId,
            currentAppName: snapshot?.appName ?? environment?.activeAppName,
            currentWindowTitle: snapshot?.windowTitle ?? environment?.activeWindowTitle,
            timeInCurrentApp: latestEngagementState?.foregroundDuration ?? signalTracker.timeInCurrentApp(),
            recentSwitchCount: signalTracker.recentSwitchCount(),
            hasEnoughSignals: signalTracker.hasEnoughSignals || !liveBuffer.signals.isEmpty,
            focusAnalysis: latestFocusAnalysis
        )
    }

    private func applyPermissionStateToEnvironment() {
        environment?.capabilities = capabilities
        environment?.permissionState = permissionState
        environment?.setSemanticHintIfChanged(
            latestSemanticInference.shouldSurface ? latestSemanticInference.displayPhrase : nil
        )
        syncDerivedEnvironmentState(memoryReadiness: environment?.memoryReadiness ?? .observing)
    }

    func syncDerivedEnvironmentState(
        memoryReadiness: NoxMemoryReadiness,
        emerging: [NoxEmergingMemoryObservation]? = nil,
        maturity: NoxMemoryMaturity? = nil
    ) {
        guard let environment else { return }
        let observations = emerging ?? environment.memoryEmergence.emergingObservations
        let resolvedMaturity = maturity ?? environment.memoryEmergence.maturity
        let rows = NoxCapabilityMatrix.rows(
            capabilities: capabilities,
            memoryReadiness: memoryReadiness,
            interactionPipelineActive: interactionCollector.isPipelineActive
        )
        environment.setCapabilityRowsIfChanged(rows)
        let emergence = NoxMemoryEmergence(
            continuitySeconds: signalTracker.observationContinuitySeconds(),
            readiness: memoryReadiness,
            liveSignalCount: liveBuffer.signals.count,
            continuityNote: continuityNote,
            maturity: resolvedMaturity,
            emergingObservations: observations
        )
        environment.setMemoryEmergenceIfChanged(emergence)
        environment.memoryMaturity = resolvedMaturity
        environment.setSemanticHintIfChanged(latestSemanticInference.shouldSurface ? primarySemanticHint() : nil)
    }

    private func ingestInteractionEvent(_ event: NoxEvent) {
        switch event.type {
        case .typingStarted, .typingBurst, .scrollActivity, .mouseActivity,
             .interactionIdle, .interactionActive:
            metricsAggregator.ingest(event: event)
        default:
            break
        }
    }

    private func scheduleSemanticEvaluation(immediate: Bool = false) {
        semanticEvaluationTask?.cancel()
        semanticEvaluationTask = Task { @MainActor in
            if !immediate {
                try? await Task.sleep(for: .milliseconds(120))
            }
            guard !Task.isCancelled else { return }
            await evaluateSemantics()
        }
    }

    private func applyIdleOnly(from snapshot: NoxActivitySnapshot) {
        environment?.idleSeconds = snapshot.idleSeconds
        environment?.isUserIdle = snapshot.isUserIdle
        recalculatePresence()
    }

    private func shouldIngestWandering(at date: Date) -> Bool {
        if let lastWanderingIngestAt,
           date.timeIntervalSince(lastWanderingIngestAt) < 20 {
            return false
        }
        lastWanderingIngestAt = date
        return true
    }

    private func wanderingSnapshot(from state: NoxEngagementState) -> NoxActivitySnapshot {
        NoxActivitySnapshot(
            appName: "Fragmented navigation",
            bundleId: "dev.nox.navigation.wandering",
            windowTitle: "Unstable context traversal",
            documentURL: nil,
            processId: 0,
            idleSeconds: state.snapshot.idleSeconds,
            isUserIdle: state.snapshot.isUserIdle,
            capturedAt: state.observedAt
        )
    }

    private func evaluateSemantics(at date: Date = Date()) async {
        if let snapshot = lastSnapshot, NoxSelfExclusion.shouldIgnore(snapshot: snapshot) {
            return
        }

        let semanticDomain = resolvedDomain(from: lastSnapshot)
        let browser = NoxBrowserContextClassifier().classify(
            bundleId: lastSnapshot?.bundleId ?? environment?.activeBundleId,
            windowTitle: lastSnapshot?.windowTitle ?? environment?.activeWindowTitle,
            domain: semanticDomain
        )

        let dominantEvidence = latestContextEvidence
        let context = NoxSemanticContext(
            capabilities: capabilities,
            bundleId: lastSnapshot?.bundleId ?? environment?.activeBundleId,
            appName: lastSnapshot?.appName ?? environment?.activeAppName,
            windowTitle: sanitizedWindowTitle(),
            domain: resolvedDomain(from: lastSnapshot),
            metrics: metricsAggregator.snapshot(at: date),
            timeInCurrentApp: latestEngagementState?.foregroundDuration ?? signalTracker.timeInCurrentApp(at: date),
            recentSwitchCount: signalTracker.recentSwitchCount(at: date),
            isUserIdle: lastSnapshot?.isUserIdle ?? environment?.isUserIdle ?? false,
            idleSeconds: lastSnapshot?.idleSeconds ?? environment?.idleSeconds ?? 0,
            nearbyBundleIds: recentBundleIds,
            focusHint: NoxFocusModeReader.currentHint(),
            hourOfDay: Calendar.current.component(.hour, from: date),
            observationContinuitySeconds: signalTracker.observationContinuitySeconds(at: date),
            browserCategory: browser.category,
            dominantContextType: dominantEvidence?.safeOutput.dominantContextType,
            dominantContextConfidence: dominantEvidence?.semantic.dominanceScore ?? 0,
            fragmentationSwitchCount: latestEngagementState?.isHardStabilized == true
                ? signalTracker.fragmentationSwitchCount(at: date)
                : 0
        )

        latestSemanticInference = semanticEngine.infer(context: context)
        environment?.semanticInference = latestSemanticInference
        if let evidence = latestContextEvidence,
           let snapshot = lastSnapshot,
           evidence.semantic.dominanceScore >= 0.4,
           evidence.safeOutput.displayLabel != snapshot.appName {
            environment?.setSemanticHintIfChanged(evidence.safeOutput.displayLabel)
        } else {
            environment?.setSemanticHintIfChanged(latestSemanticInference.shouldSurface ? primarySemanticHint() : nil)
        }

        if let signal = NoxSemanticLiveSignalPresenter.makeSignal(
            from: latestSemanticInference,
            at: date,
            observationContinuitySeconds: signalTracker.observationContinuitySeconds(at: date)
        ) {
            liveBuffer.prepend(signal)
            publishLiveSignals()
        } else {
            publishLiveSignals()
        }

        if NoxQuietModeEngine.shouldIngestSemanticMemory(preferences.pauseState),
           latestEngagementState?.isHardStabilized == true {
            let resurfacing = try? await memoryCoordinator.ingestSemantic(
                inference: latestSemanticInference,
                appName: context.appName,
                bundleId: context.bundleId,
                context: context
            )
            if let resurfacing,
               NoxQuietModeEngine.shouldResurface(preferences.pauseState),
               NoxQuietModeEngine.shouldObserveContinuity(preferences.pauseState) {
                liveBuffer.prepend(
                    NoxLiveSignal(
                        id: "continuity-\(resurfacing.threadId)",
                        timestamp: resurfacing.timestamp,
                        text: resurfacing.primaryText,
                        kind: .awareness,
                        lifecycle: .transient(240)
                    )
                )
                publishLiveSignals()
            }
            _ = try? await memoryCoordinator.checkpointSemanticSpan(at: date)
        }
        scheduleMemoryReload()
    }

    private func evaluateSemanticsIfNeeded(
        for snapshot: NoxActivitySnapshot,
        force: Bool,
        at date: Date
    ) async {
        guard semanticCadence.shouldEvaluate(snapshot: snapshot, force: force, now: date) else {
            return
        }
        await evaluateSemantics(at: date)
    }

    private func primarySemanticHint() -> String? {
        NoxSemanticLabelCatalog.presenceHint(from: latestSemanticInference)
    }

    @discardableResult
    private func evaluateContext(
        for snapshot: NoxActivitySnapshot,
        resetDominance: Bool
    ) -> NoxContextEvidence {
        let evidence = contextPipeline.evaluate(
            snapshot: snapshot,
            capabilities: capabilities,
            metrics: metricsAggregator.snapshot(at: snapshot.capturedAt),
            stableDurationSeconds: signalTracker.timeInCurrentApp(at: snapshot.capturedAt),
            recentSwitchCount: signalTracker.recentSwitchCount(at: snapshot.capturedAt),
            resetDominance: resetDominance
        )
        latestContextEvidence = evidence
        environment?.appContext = evidence.appContext
        environment?.contextDebugSnapshot = NoxContextDebugFormatter.make(evidence: evidence)
        return evidence
    }

    private func publishContextLabel(
        from evidence: NoxContextEvidence,
        snapshot: NoxActivitySnapshot,
        force: Bool = false
    ) {
        let label = evidence.safeOutput.displayLabel
        guard label != snapshot.appName else {
            if force || contextHeartbeat.shouldPublishLabel("") {
                environment?.activeContextLabel = nil
                environment?.setSemanticHintIfChanged(nil)
                liveBuffer.replaceLivePulse(label: "")
            }
            return
        }
        guard force || contextHeartbeat.shouldPublishLabel(label) else { return }
        environment?.activeContextLabel = label
        environment?.setSemanticHintIfChanged(label)
        liveBuffer.replaceLivePulse(label: label, at: snapshot.capturedAt)
        publishLiveSignals()
        contextHeartbeat.recordEvaluation(
            snapshot: snapshot,
            label: label,
            now: snapshot.capturedAt
        )
    }

    private func isPassiveDominant(_ type: NoxDominantContextType) -> Bool {
        type == .watching || type == .listening
    }

    private func shouldTreatAsPassivePlayback(
        evidence: NoxContextEvidence,
        snapshot: NoxActivitySnapshot
    ) -> Bool {
        if isPassiveDominant(evidence.safeOutput.dominantContextType) { return true }
        let domain = resolvedDomain(from: snapshot)
        let browser = NoxBrowserContextClassifier().classify(
            bundleId: snapshot.bundleId,
            windowTitle: snapshot.windowTitle,
            domain: domain
        )
        return NoxPassiveMediaContext.indicatesPassiveMedia(
            title: snapshot.windowTitle,
            domain: domain,
            browserCategory: browser.category
        )
    }

    private func resolvedDomain(from snapshot: NoxActivitySnapshot?) -> String? {
        domainClassifier.domain(
            from: snapshot?.windowTitle ?? environment?.activeWindowTitle,
            documentURL: snapshot?.documentURL
        )
    }

    private func sanitizedWindowTitle() -> String? {
        let title = lastSnapshot?.windowTitle ?? environment?.activeWindowTitle
        let sensitivity = NoxSensitiveContextHandler.sensitivity(
            domain: domainClassifier.domain(from: title, documentURL: lastSnapshot?.documentURL),
            title: title,
            bundleId: lastSnapshot?.bundleId
        )
        return NoxSensitiveContextHandler.sanitizedTitle(title, sensitivity: sensitivity)
    }

    private func trackRecentBundle(_ bundleId: String?) {
        guard let bundleId, !bundleId.isEmpty else { return }
        guard !NoxSelfExclusion.isExcluded(bundleId: bundleId) else { return }
        recentBundleIds.removeAll { $0 == bundleId }
        recentBundleIds.insert(bundleId, at: 0)
        recentBundleIds = Array(recentBundleIds.prefix(6))
    }

    private func runtimeCapabilities(from base: NoxCapabilityState) -> NoxCapabilityState {
        NoxCapabilityState(
            accessibilityGranted: base.accessibilityGranted,
            screenRecordingGranted: base.screenRecordingGranted,
            appAwarenessAvailable: base.appAwarenessAvailable,
            windowAwarenessAvailable: base.windowAwarenessAvailable,
            interactionSignalsAvailable: interactionCollector.isPipelineActive
        )
    }

    private func scheduleMemoryMaintenance() {
        eventPipeline.scheduleStartupMaintenance { [weak self] in
            guard let self else { return }
            _ = try? await memoryCoordinator.runMemoryMaintenance(
                timelineStore: timelineStore,
                sessionStore: sessionStore,
                policy: retentionPolicy
            )
        }
    }

    private func startMaintenanceLoop() {
        eventPipeline.startMaintenanceLoop(
            intervalSeconds: retentionPolicy.maintenanceIntervalSeconds
        ) { [weak self] in
            guard let self else { return }
            _ = try? await memoryCoordinator.runMemoryMaintenance(
                timelineStore: timelineStore,
                sessionStore: sessionStore,
                policy: retentionPolicy
            )
        }
    }

    private func hydrateFromPersistence() async {
        ambientState = (try? await ambientStateStore.load()) ?? .empty
        var ambient = ambientState

        if let session = ambient.systemState.caffeinateSession, session.isActive {
            NoxCaffeinateController.shared.restore(session: session)
        }

        if let persisted = try? await ambientStateStore.loadSignalTracker() {
            signalTracker.restore(from: persisted)
        }

        recentBundleIds = ambient.recentBundleIds.filter { !NoxSelfExclusion.isExcluded(bundleId: $0) }

        if let raw = ambient.lastPresence, let restored = NoxPresenceState(rawValue: raw) {
            environment?.presence = restored
            presenceStabilizer.reset(to: restored)
        }

        environment?.activeAppName = ambient.lastActiveAppName
        environment?.activeBundleId = ambient.lastActiveBundleId
        environment?.activeWindowTitle = ambient.lastActiveWindowTitle

        let frontBundle = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        if let recovery = try? await memoryCoordinator.performRestartRecovery(
            sessionStore: sessionStore,
            ambient: ambient,
            currentBundleId: frontBundle
        ) {
            if let resumed = recovery.resumedSession {
                sessionDetector.restore(session: resumed)
                environment?.sessionSummary = resumed.summaryLine
            }
            continuityNote = recovery.continuityNote ?? lastObservedContinuityNote(from: ambient)
        } else {
            continuityNote = lastObservedContinuityNote(from: ambient)
        }

        let records = (try? await timelineStore.getRecentEvents(limit: 50)) ?? []
        environment?.timelineEvents = records
        hydrateLiveFromRecentEvents()
        await reloadMemoryView()
        syncDerivedEnvironmentState(memoryReadiness: environment?.memoryReadiness ?? .observing)

        ambient.continuityNote = nil
        ambientState = ambient
        try? await ambientStateStore.save(ambient)
    }

    private func lastObservedContinuityNote(from ambient: NoxAmbientState) -> String? {
        guard let app = ambient.lastActiveAppName else { return nil }
        if let shutdown = ambient.lastShutdownAt {
            let gap = max(1, Int(Date().timeIntervalSince(shutdown) / 60))
            return "Last observed \(app) · restart \(gap)m ago"
        }
        return "Last observed \(app) before restart"
    }

    private func persistActiveSessionIfNeeded() async {
        guard let session = sessionDetector.exportCurrentSession() else { return }
        guard !NoxSelfExclusion.isExcluded(bundleId: session.primaryBundleId, appName: session.primaryApp) else {
            return
        }
        try? await sessionStore.upsert(session)
    }

    private func persistSession(from event: NoxEvent) async {
        guard case .session(let payload) = event.payload else { return }
        guard !NoxSelfExclusion.isExcluded(bundleId: payload.primaryBundleId, appName: payload.primaryApp) else {
            return
        }

        if event.type == .sessionStarted, let session = sessionDetector.exportCurrentSession() {
            try? await sessionStore.upsert(session)
            return
        }

        guard event.type == .sessionEnded else { return }

        let endedAt = event.timestamp
        let startedAt = endedAt.addingTimeInterval(-Double(payload.durationMs) / 1000)
        let session = NoxWorkSession(
            id: payload.sessionId,
            startedAt: startedAt,
            endedAt: endedAt,
            primaryApp: payload.primaryApp,
            primaryBundleId: payload.primaryBundleId,
            interruptionCount: 0,
            appSwitchCount: 0,
            confidence: payload.confidence,
            state: .ended
        )
        try? await sessionStore.upsert(session, endReason: .completed)
    }

    func refreshAwarenessSnapshot() {
        guard let environment else { return }
        let sensitivity = latestSemanticInference.sensitivityLevel
        environment.awarenessSnapshot = NoxAwarenessPresenter.snapshot(
            capabilities: capabilities,
            memoryReadiness: environment.memoryReadiness,
            pauseState: preferences.pauseState,
            sensitivity: sensitivity
        )
    }

    func refreshPrimaryExplanation() {
        guard let environment else { return }
        if let connector = NoxConnectorExplainability.inferenceReason(
            for: environment.connectorSnapshot
        ) {
            environment.primaryExplanation = connector
            return
        }
        environment.primaryExplanation = NoxExplainabilityPresenter.whySeeingLiveContext(
            inference: latestSemanticInference,
            awareness: environment.awarenessSnapshot
        )
    }

    func requestCalendarAccess() async {
        _ = await NoxCalendarContextProvider.requestAccessIfNeeded()
        await reloadMemoryView()
    }

    func clearConnectorContinuity() async {
        try? await connectorControl.clearConnectorDerived()
        guard let environment else { return }
        environment.connectorSnapshot = .empty
        environment.behavioralSnapshot = .empty
        environment.ambientUtilitySnapshot = .empty
        await reloadMemoryView()
    }

    func requestAmbientNotificationAuthorization() async {
        _ = await NoxAmbientNotificationEngine.requestAuthorizationIfNeeded()
    }

    func performSystemInterventionAction(_ action: NoxSystemActionCandidate) async -> NoxSystemActionOutcome {
        let continuity = signalTracker.observationContinuitySeconds()
        var persistence = ambientState.systemState
        let contradictionType = environment?.connectorSnapshot.intervention?.systemContradictionType
        let outcome = NoxSystemActionExecutor.perform(
            action,
            contradictionType: contradictionType,
            preferences: preferences.ambientUtility.systemState,
            persistence: &persistence,
            observationContinuitySeconds: continuity
        )
        ambientState.systemState = persistence
        try? await ambientStateStore.save(ambientState)
        await reloadMemoryView()
        return outcome
    }

    func stopManagedCaffeinate() async {
        if let stopped = NoxCaffeinateController.shared.stop() {
            ambientState.systemState.caffeinateSession = stopped
            try? await ambientStateStore.save(ambientState)
        }
        await reloadMemoryView()
    }

    func clearSystemActionHistory() async {
        ambientState.systemState.actionHistory = []
        ambientState.systemState.dismissedContradictions = [:]
        try? await ambientStateStore.save(ambientState)
    }
}

extension NoxContextService: NoxContextMemoryPipelineHost {}
