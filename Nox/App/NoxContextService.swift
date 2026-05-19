import AppKit
import Foundation

@MainActor
final class NoxContextService {
    private let eventBus = NoxEventBus()
    private let permissionService = NoxPermissionService()
    private let presenceEngine = NoxPresenceEngine()
    private let presenceStabilizer = NoxPresenceStabilizer()
    private let timelineStore = NoxTimelineStore()
    private let memoryCoordinator = NoxMemoryCoordinator()
    private let ambientStateStore = NoxAmbientStateStore()
    private let sessionStore = NoxSessionStore()
    private let activityObserver = NoxActivityObserver()
    private let interactionCollector = NoxInteractionSignalCollector()
    private let metricsAggregator = NoxInteractionMetricsAggregator()
    private let semanticEngine = NoxSemanticInferenceEngine()
    private let liveBuffer = NoxLiveSignalBuffer(capacity: 24)
    private let metadataExtractor = NoxMetadataExtractor()
    private let domainClassifier = NoxDomainClassifier()
    private var contextPipeline = NoxContextAcquisitionPipeline()
    private let contextHeartbeat = NoxContextHeartbeat()
    private var latestContextEvidence: NoxContextEvidence?

    private var sessionDetector = NoxSessionDetector()
    private var signalTracker = NoxActivitySignalTracker()
    private var recentBundleIds: [String] = []
    private var latestSemanticInference = NoxSemanticInference.hidden
    private var lastSnapshot: NoxActivitySnapshot?
    private var lastActiveSignalByBundle: [String: Date] = [:]
    private var capabilities = NoxCapabilityState.unavailable
    private var permissionState = NoxPermissionState.limited
    private var latestFocusAnalysis: NoxFocusAnalysis?
    private var memoryReloadTask: Task<Void, Never>?
    private var semanticEvaluationTask: Task<Void, Never>?
    private var semanticHeartbeatTask: Task<Void, Never>?
    private var maintenanceTask: Task<Void, Never>?
    private var continuityNote: String?
    private var ambientState: NoxAmbientState = .empty
    private var preferences = NoxAmbientPreferences.default
    private let preferencesStore = NoxPreferencesStore()
    private lazy var memoryControl = NoxMemoryControlCoordinator(
        memoryCoordinator: memoryCoordinator,
        timelineStore: timelineStore
    )
    private let connectorSignalStore = NoxConnectorSignalStore()
    private lazy var connectorControl = NoxConnectorControlCoordinator(
        signalStore: connectorSignalStore
    )
    private let retentionPolicy = NoxMemoryRetentionPolicy.default
    private weak var environment: AppEnvironment?

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
            preferences = (try? await preferencesStore.loadPreferences()) ?? .default
            environment?.preferences = preferences
            await hydrateFromPersistence()
            scheduleMemoryMaintenance()
        } catch {
            environment?.timelineEvents = []
            environment?.timelineSections = []
            environment?.memoryReadiness = .observing
        }

        eventBus.subscribe { [weak self] event in
            Task { @MainActor in
                await self?.handle(event)
            }
        }

        activityObserver.start(
            onEvent: { [weak self] event in
                Task { @MainActor in
                    self?.eventBus.publish(event)
                }
            },
            onSnapshot: { [weak self] snapshot in
                Task { @MainActor in
                    await self?.ingestSnapshot(snapshot)
                }
            }
        )

        startPermissionPolling()
        startInteractionSampling()
        startSemanticHeartbeat()
        startMaintenanceLoop()
    }

    func stop() {
        activityObserver.stop()
        memoryReloadTask?.cancel()
        semanticEvaluationTask?.cancel()
        semanticHeartbeatTask?.cancel()
        maintenanceTask?.cancel()
    }

    func checkpointBeforeTerminate() async {
        guard let environment else { return }

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
        guard let environment else { return }
        let query = NoxMemoryQuery(text: environment.memorySearchText, period: environment.memoryPeriod)
        do {
            let view = try await memoryCoordinator.loadView(
                period: environment.memoryPeriod,
                query: query
            )
            environment.timelineSections = view.sections
            environment.dayStats = view.stats
            environment.focusAnalysis = view.focus
            latestFocusAnalysis = view.focus
            let timelineItems = view.sections.flatMap(\.items)
            environment.memoryDensity = density(for: view.stats, blockCount: timelineItems.count)
            environment.daySemanticOverview = NoxDaySemanticFraming.overview(
                blocks: timelineItems,
                stats: view.stats,
                continuityThreads: view.continuityThreads
            )

            let range = environment.memoryPeriod.dateRange()
            let spans = try await memoryCoordinator.activitySpans(period: environment.memoryPeriod)
            let connectorSnapshot = await refreshConnectorLayer(
                spans: spans,
                stats: view.stats,
                focus: view.focus,
                range: range
            )
            environment.connectorSnapshot = connectorSnapshot

            let reflective = try await memoryCoordinator.loadReflectiveContinuity(
                period: environment.memoryPeriod,
                stats: view.stats,
                focus: view.focus,
                continuityThreads: view.continuityThreads,
                continuityNote: continuityNote,
                lastShutdownAt: ambientState.lastShutdownAt,
                lastMorningAt: ambientState.lastMorningSummaryAt,
                lastResurfacingShownAt: ambientState.lastResurfacingShownAt,
                liveSignalCount: liveBuffer.signals.count,
                continuitySeconds: signalTracker.observationContinuitySeconds(),
                connectorSnapshot: connectorSnapshot
            )
            environment.longHorizonSnapshot = reflective.longHorizon
            environment.morningSummary = reflective.morningSummary
            environment.memoryMaturity = reflective.memoryMaturity
            let readiness = memoryReadiness(
                blocks: timelineItems,
                liveCount: liveBuffer.signals.count,
                stats: view.stats,
                maturity: reflective.memoryMaturity
            )
            environment.memoryReadiness = readiness

            if reflective.morningSummary != nil {
                ambientState.lastMorningSummaryAt = Date()
            }
            if !reflective.longHorizon.resurfacingNotes.isEmpty {
                ambientState.lastResurfacingShownAt = Date()
            }
            if connectorSnapshot.intervention != nil {
                ambientState.lastConnectorInterventionAt = Date()
            }
            ambientState.lastConnectorFocusKind = view.focus.kind?.rawValue
            var densities = ambientState.recentConnectorDensities
            densities.append(NoxCadenceDensity.score(for: view.stats))
            if densities.count > 14 { densities.removeFirst(densities.count - 14) }
            ambientState.recentConnectorDensities = densities
            try? await ambientStateStore.save(ambientState)

            let periodEmerging = await periodScopedEmergence(
                period: environment.memoryPeriod,
                range: range,
                threads: view.continuityThreads,
                stats: view.stats
            )
            syncDerivedEnvironmentState(
                memoryReadiness: readiness,
                emerging: periodEmerging.observations,
                maturity: periodEmerging.maturity
            )
            refreshAwarenessSnapshot()
            refreshPrimaryExplanation()
            recalculatePresence()
        } catch {
            environment.timelineSections = []
            environment.dayStats = .empty
            environment.memoryReadiness = .building
        }
    }

    func refreshPermissionState() {
        refreshPermissionState(force: false)
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
        activityObserver.refreshAccessibilityBridge()
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

        eventBus.publish(
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
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                refreshPermissionState(force: false)
            }
        }
    }

    private func startInteractionSampling() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                interactionCollector.sample { [weak self] event in
                    self?.eventBus.publish(event)
                }
            }
        }
    }

    private func startSemanticHeartbeat() {
        semanticHeartbeatTask?.cancel()
        semanticHeartbeatTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                guard let snapshot = lastSnapshot else { continue }
                if NoxSelfExclusion.shouldIgnore(snapshot: snapshot) { continue }
                let evidence = evaluateContext(for: snapshot, resetDominance: false)
                guard contextHeartbeat.shouldEvaluate(snapshot: snapshot, evidence: evidence) else {
                    continue
                }
                publishContextLabel(from: evidence, snapshot: snapshot)
                await evaluateSemantics(at: snapshot.capturedAt)
            }
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
        !NoxForbiddenMemoryContent.mustNotPersistToWarmTimeline(eventType: event.type)
    }

    private func persist(_ event: NoxEvent) async {
        do {
            try await timelineStore.insertEvent(from: event)
            let records = try await timelineStore.getRecentEvents(limit: 50)
            environment?.timelineEvents = records
            try? await timelineStore.pruneOldEvents(olderThan: retentionPolicy.warmTimelineDays)
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
        appendLiveSignalsFromSnapshot(snapshot, previous: previous, evidence: contextEvidence)
        signalTracker.recordSnapshot(snapshot)

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
        _ = sessionDetector.ingest(snapshot: snapshot, isProductive: isProductive) { [weak self] event in
            Task { @MainActor in
                self?.eventBus.publish(event)
            }
        }
        environment?.sessionSummary = sessionDetector.currentSession?.summaryLine
        await persistActiveSessionIfNeeded()
        trackRecentBundle(snapshot.bundleId)
        await evaluateSemantics(at: snapshot.capturedAt)
        recalculatePresence()

        if NoxQuietModeEngine.shouldIngestTimeline(preferences.pauseState) {
            Task {
                if let previous, previous.bundleId != snapshot.bundleId {
                    try? await memoryCoordinator.ingestAppChange(from: previous, to: snapshot)
                } else {
                    try? await memoryCoordinator.ingestSnapshot(snapshot)
                }
                await reloadMemoryView()
            }
        }
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
        environment?.liveSignals = liveBuffer.visibleSignals(capabilities: capabilities)
        syncDerivedEnvironmentState(memoryReadiness: environment?.memoryReadiness ?? .observing)
    }

    private func scheduleMemoryReload() {
        memoryReloadTask?.cancel()
        memoryReloadTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            await reloadMemoryView()
        }
    }

    private func processSignals(for event: NoxEvent) {
        switch event.payload {
        case .appChanged(let payload):
            guard !NoxSelfExclusion.isExcluded(bundleId: payload.bundleId, appName: payload.appName) else {
                return
            }
            sessionDetector.recordAppSwitch()
            trackRecentBundle(payload.bundleId)
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

    private func recalculatePresence() {
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
            timeInCurrentApp: signalTracker.timeInCurrentApp(),
            recentSwitchCount: signalTracker.recentSwitchCount(),
            hasEnoughSignals: signalTracker.hasEnoughSignals || !liveBuffer.signals.isEmpty,
            focusAnalysis: latestFocusAnalysis
        )
    }

    private func applyPermissionStateToEnvironment() {
        environment?.capabilities = capabilities
        environment?.permissionState = permissionState
        environment?.semanticHint = latestSemanticInference.shouldSurface
            ? latestSemanticInference.displayPhrase
            : nil
        syncDerivedEnvironmentState(memoryReadiness: environment?.memoryReadiness ?? .observing)
    }

    private func syncDerivedEnvironmentState(
        memoryReadiness: NoxMemoryReadiness,
        emerging: [NoxEmergingMemoryObservation]? = nil,
        maturity: NoxMemoryMaturity? = nil
    ) {
        guard let environment else { return }
        let observations = emerging ?? environment.memoryEmergence.emergingObservations
        let resolvedMaturity = maturity ?? environment.memoryEmergence.maturity
        environment.capabilityRows = NoxCapabilityMatrix.rows(
            capabilities: capabilities,
            memoryReadiness: memoryReadiness,
            interactionPipelineActive: interactionCollector.isPipelineActive
        )
        environment.memoryEmergence = NoxMemoryEmergence(
            continuitySeconds: signalTracker.observationContinuitySeconds(),
            readiness: memoryReadiness,
            liveSignalCount: liveBuffer.signals.count,
            continuityNote: continuityNote,
            maturity: resolvedMaturity,
            emergingObservations: observations
        )
        environment.memoryMaturity = resolvedMaturity
        environment.semanticHint = latestSemanticInference.shouldSurface
            ? primarySemanticHint()
            : nil
    }

    private func periodScopedEmergence(
        period: NoxMemoryPeriod,
        range: (start: Date, end: Date),
        threads: [NoxContinuityThread],
        stats: NoxMemoryDayStats
    ) async -> (observations: [NoxEmergingMemoryObservation], maturity: NoxMemoryMaturity) {
        let spans = (try? await memoryCoordinator.semanticSpans(from: range.start, to: range.end)) ?? []
        let includeLive = period == .today
        let result = NoxEmergingMemoryEngine.observe(
            semanticSpans: spans,
            openSpan: includeLive ? memoryCoordinator.currentOpenSemanticSpan : nil,
            threads: threads,
            stats: stats,
            liveSignalCount: includeLive ? liveBuffer.signals.count : 0,
            continuitySeconds: includeLive ? signalTracker.observationContinuitySeconds() : 0
        )
        return (result.observations, result.maturity)
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
            timeInCurrentApp: signalTracker.timeInCurrentApp(at: date),
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
            fragmentationSwitchCount: signalTracker.fragmentationSwitchCount(at: date)
        )

        latestSemanticInference = semanticEngine.infer(context: context)
        environment?.semanticInference = latestSemanticInference
        if let evidence = latestContextEvidence,
           let snapshot = lastSnapshot,
           evidence.semantic.dominanceScore >= 0.4,
           evidence.safeOutput.displayLabel != snapshot.appName {
            environment?.semanticHint = evidence.safeOutput.displayLabel
        } else {
            environment?.semanticHint = latestSemanticInference.shouldSurface
                ? primarySemanticHint()
                : nil
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

        if NoxQuietModeEngine.shouldIngestSemanticMemory(preferences.pauseState) {
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
                environment?.semanticHint = nil
                liveBuffer.replaceLivePulse(label: "")
            }
            return
        }
        guard force || contextHeartbeat.shouldPublishLabel(label) else { return }
        environment?.activeContextLabel = label
        environment?.semanticHint = label
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

    private func memoryReadiness(
        blocks: [NoxTimelineBlockItem],
        liveCount: Int,
        stats: NoxMemoryDayStats,
        maturity: NoxMemoryMaturity = .transient
    ) -> NoxMemoryReadiness {
        if !blocks.isEmpty { return .ready }
        if maturity == .stable || maturity == .durable { return .building }
        if stats.totalActiveMs >= 60_000 || stats.appSwitchCount >= 2 { return .building }
        if liveCount >= 2 || maturity == .emerging { return .building }
        return .observing
    }

    private func scheduleMemoryMaintenance() {
        maintenanceTask?.cancel()
        maintenanceTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(45))
            guard !Task.isCancelled else { return }
            _ = try? await memoryCoordinator.runMemoryMaintenance(
                timelineStore: timelineStore,
                sessionStore: sessionStore,
                policy: retentionPolicy
            )
        }
    }

    private func startMaintenanceLoop() {
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(retentionPolicy.maintenanceIntervalSeconds))
                guard !Task.isCancelled else { return }
                _ = try? await memoryCoordinator.runMemoryMaintenance(
                    timelineStore: timelineStore,
                    sessionStore: sessionStore,
                    policy: retentionPolicy
                )
            }
        }
    }

    private func density(for stats: NoxMemoryDayStats, blockCount: Int) -> Double {
        let activityFactor = min(1.0, Double(stats.totalActiveMs) / Double(6 * 3_600_000))
        let blockFactor = min(1.0, Double(blockCount) / 24.0)
        let liveFactor = min(1.0, Double(liveBuffer.signals.count) / 12.0)
        return 0.35 + (activityFactor * 0.3) + (blockFactor * 0.15) + (liveFactor * 0.12)
    }

    private func hydrateFromPersistence() async {
        ambientState = (try? await ambientStateStore.load()) ?? .empty
        var ambient = ambientState

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

    private func refreshAwarenessSnapshot() {
        guard let environment else { return }
        let sensitivity = latestSemanticInference.sensitivityLevel
        environment.awarenessSnapshot = NoxAwarenessPresenter.snapshot(
            capabilities: capabilities,
            memoryReadiness: environment.memoryReadiness,
            pauseState: preferences.pauseState,
            sensitivity: sensitivity
        )
    }

    private func refreshPrimaryExplanation() {
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
        await reloadMemoryView()
    }

    private func refreshConnectorLayer(
        spans: [NoxActivitySpan],
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        range: (start: Date, end: Date)
    ) async -> NoxConnectorContinuitySnapshot {
        let stored = (try? await connectorSignalStore.recentCadencePatterns()) ?? []
        let previousKind = ambientState.lastConnectorFocusKind.flatMap(NoxFocusBlockKind.init(rawValue:))
        let gapHours: Double
        if let started = ambientState.observationStartedAt {
            gapHours = max(0, Date().timeIntervalSince(started) / 3600)
        } else {
            gapHours = 0
        }

        return await NoxConnectorContinuityOrchestrator.refresh(
            preferences: preferences.connectors,
            stats: stats,
            focus: focus,
            spans: spans,
            range: range,
            storedPatterns: stored,
            recentDailyDensity: ambientState.recentConnectorDensities,
            previousFocusKind: previousKind,
            observationGapHours: gapHours,
            lastInterventionAt: ambientState.lastConnectorInterventionAt,
            signalStore: connectorSignalStore
        )
    }
}
