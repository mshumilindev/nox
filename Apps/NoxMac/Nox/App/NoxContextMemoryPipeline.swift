import Foundation
import NoxCore
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore

/// Heavy memory/dashboard refresh and cross-domain orchestration (extracted from `NoxContextService`).
@MainActor
final class NoxContextMemoryPipeline {
    private let memoryCoordinator: NoxMemoryCoordinator
    private let observatoryProvider: NoxObservatoryDataProvider
    private let connectorSignalStore: NoxConnectorSignalStore
    private let behavioralSignalStore: NoxBehavioralIntelligenceSignalStore
    private let ambientStateStore: NoxAmbientStateStore
    private weak var host: NoxContextMemoryPipelineHost?

    init(
        memoryCoordinator: NoxMemoryCoordinator,
        observatoryProvider: NoxObservatoryDataProvider,
        connectorSignalStore: NoxConnectorSignalStore,
        behavioralSignalStore: NoxBehavioralIntelligenceSignalStore,
        ambientStateStore: NoxAmbientStateStore,
        host: NoxContextMemoryPipelineHost
    ) {
        self.memoryCoordinator = memoryCoordinator
        self.observatoryProvider = observatoryProvider
        self.connectorSignalStore = connectorSignalStore
        self.behavioralSignalStore = behavioralSignalStore
        self.ambientStateStore = ambientStateStore
        self.host = host
    }

    func reloadMemoryView() async {
        guard let host, let environment = host.environment else { return }
        let query = NoxMemoryQuery(text: environment.memorySearchText, period: environment.memoryPeriod)
        do {
            let view = try await memoryCoordinator.loadView(
                period: environment.memoryPeriod,
                query: query
            )
            environment.dayStats = view.stats
            environment.focusAnalysis = view.focus
            host.latestFocusAnalysis = view.focus
            let timelineItems = view.sections.flatMap(\.items)
            environment.memoryDensity = Self.density(
                for: view.stats,
                blockCount: timelineItems.count,
                liveSignalCount: host.liveBuffer.signals.count
            )
            environment.daySemanticOverview = NoxDaySemanticFraming.overview(
                blocks: timelineItems,
                stats: view.stats,
                continuityThreads: view.continuityThreads
            )

            let range = environment.memoryPeriod.dateRange()
            let spans = try await memoryCoordinator.activitySpans(period: environment.memoryPeriod)
            var connectorSnapshot = await refreshConnectorLayer(
                spans: spans,
                stats: view.stats,
                focus: view.focus,
                range: range,
                host: host
            )
            let date = Date()
            let presentationAnchor = range.end
            let lookback = date.addingTimeInterval(-14 * 24 * 3600)
            let semanticSpans = (try? await memoryCoordinator.semanticSpans(from: lookback, to: date)) ?? []
            let continuityArcs = NoxSemanticArcEngine.buildArcs(
                spans: semanticSpans,
                threads: view.continuityThreads,
                at: date
            )
            let behavioralSnapshot = await refreshBehavioralLayer(
                connectorSnapshot: connectorSnapshot,
                spans: spans,
                stats: view.stats,
                focus: view.focus,
                threads: view.continuityThreads,
                semanticSpans: semanticSpans,
                arcs: continuityArcs,
                host: host,
                at: date
            )
            let previousDominant = host.ambientState.lastDominantActivityCategory
                .flatMap(NoxActivityCategory.init(rawValue:))
            let utilitySnapshot = await refreshAmbientUtilityLayer(
                connectorSnapshot: connectorSnapshot,
                behavioralSnapshot: behavioralSnapshot,
                stats: view.stats,
                focus: view.focus,
                threads: view.continuityThreads,
                arcs: continuityArcs,
                isUserIdle: environment.isUserIdle,
                previousDominantCategory: previousDominant,
                host: host,
                at: date
            )
            environment.ambientUtilitySnapshot = utilitySnapshot

            let memoryEvolution = await refreshMemoryEvolutionLayer(
                threads: view.continuityThreads,
                arcs: continuityArcs,
                behavioralSnapshot: behavioralSnapshot,
                utilitySnapshot: utilitySnapshot,
                focus: view.focus,
                host: host,
                at: date
            )
            environment.memoryEvolutionSnapshot = memoryEvolution
            environment.observatorySnapshot = await observatoryProvider.snapshot(
                range: environment.observatoryRange,
                behavioralSnapshot: behavioralSnapshot,
                utilitySnapshot: utilitySnapshot,
                memoryEvolutionSnapshot: memoryEvolution,
                connectorSnapshot: connectorSnapshot,
                at: date
            )
            if !host.preferences.connectors.continuityEnrichmentPaused {
                let intervention = utilitySnapshot.refinedIntervention
                    ?? behavioralSnapshot.recommendedIntervention
                connectorSnapshot = connectorSnapshot.replacingIntervention(intervention)
            }
            environment.connectorSnapshot = connectorSnapshot
            environment.behavioralSnapshot = behavioralSnapshot

            let reflective = try await memoryCoordinator.loadReflectiveContinuity(
                period: environment.memoryPeriod,
                stats: view.stats,
                focus: view.focus,
                continuityThreads: view.continuityThreads,
                continuityNote: host.continuityNote,
                lastShutdownAt: host.ambientState.lastShutdownAt,
                lastMorningAt: host.ambientState.lastMorningSummaryAt,
                lastResurfacingShownAt: host.ambientState.lastResurfacingShownAt,
                liveSignalCount: host.liveBuffer.signals.count,
                continuitySeconds: host.signalTracker.observationContinuitySeconds(),
                connectorSnapshot: connectorSnapshot,
                behavioralSnapshot: behavioralSnapshot,
                calmnessProfile: utilitySnapshot.calmness,
                utilityCalibration: utilitySnapshot.calibration,
                memoryEvolution: memoryEvolution
            )
            environment.longHorizonSnapshot = reflective.longHorizon
            environment.morningSummary = reflective.morningSummary
            environment.memoryMaturity = reflective.memoryMaturity
            let readiness = Self.memoryReadiness(
                blocks: timelineItems,
                liveCount: host.liveBuffer.signals.count,
                stats: view.stats,
                maturity: reflective.memoryMaturity
            )
            environment.memoryReadiness = readiness

            if reflective.morningSummary != nil {
                host.ambientState.lastMorningSummaryAt = Date()
            }
            if !reflective.longHorizon.resurfacingNotes.isEmpty {
                host.ambientState.lastResurfacingShownAt = Date()
            }
            if connectorSnapshot.intervention != nil {
                host.ambientState.lastConnectorInterventionAt = Date()
            }
            if utilitySnapshot.primaryNudge != nil {
                host.ambientState.lastContextualNudgeAt = Date()
            }
            if let notification = utilitySnapshot.notificationCandidate,
               host.preferences.ambientUtility.ambientNotificationsEnabled {
                await deliverAmbientNotificationIfNeeded(notification, host: host)
            }
            host.ambientState.lastConnectorFocusKind = view.focus.kind?.rawValue
            host.ambientState.lastDominantActivityCategory = view.stats.dominantCategory?.rawValue
            var densities = host.ambientState.recentConnectorDensities
            densities.append(NoxCadenceDensity.score(for: view.stats))
            if densities.count > 14 { densities.removeFirst(densities.count - 14) }
            host.ambientState.recentConnectorDensities = densities
            try? await ambientStateStore.save(host.ambientState)

            let periodEmerging = await periodScopedEmergence(
                period: environment.memoryPeriod,
                range: range,
                threads: view.continuityThreads,
                stats: view.stats,
                host: host
            )

            let enrichedSelectedPeriod = NoxTemporalMemoryRowPresenter.enrich(
                sections: view.sections,
                threads: view.continuityThreads,
                arcs: continuityArcs,
                evolution: memoryEvolution,
                ecologyCoupling: host.ambientState.memoryEvolution.ecologyCoupling,
                period: environment.memoryPeriod,
                at: presentationAnchor
            )
            let todayQuery = NoxMemoryQuery(text: environment.memorySearchText, period: .today)
            let galaxyView = try await memoryCoordinator.loadView(period: .today, query: todayQuery)
            let galaxyItems = galaxyView.sections.flatMap(\.items)
            let galaxyArcs = NoxSemanticArcEngine.buildArcs(
                spans: semanticSpans,
                threads: galaxyView.continuityThreads,
                at: date
            )
            environment.galaxyTimelineSections = NoxTemporalMemoryRowPresenter.enrich(
                sections: galaxyView.sections,
                threads: galaxyView.continuityThreads,
                arcs: galaxyArcs,
                evolution: memoryEvolution,
                ecologyCoupling: host.ambientState.memoryEvolution.ecologyCoupling,
                period: .today,
                at: Date()
            )
            environment.galaxyDayOverview = NoxDaySemanticFraming.overview(
                blocks: galaxyItems,
                stats: galaxyView.stats,
                continuityThreads: galaxyView.continuityThreads
            )
            environment.dayStats = galaxyView.stats
            environment.galaxyEmergence = NoxMemoryEmergence(
                continuitySeconds: host.signalTracker.observationContinuitySeconds(),
                readiness: readiness,
                liveSignalCount: host.liveBuffer.signals.count,
                continuityNote: host.continuityNote,
                maturity: reflective.memoryMaturity,
                emergingObservations: periodEmerging.observations
            )
            if environment.memoryPeriod == .today {
                environment.deepSpaceTimelineSections = []
            } else {
                environment.deepSpaceTimelineSections = enrichedSelectedPeriod
            }
            environment.deepSpaceEntries = NoxMemoryEcologyPresenter.deepSpaceEntries(
                longHorizon: reflective.longHorizon,
                evolution: memoryEvolution
            )

            host.syncDerivedEnvironmentState(
                memoryReadiness: readiness,
                emerging: periodEmerging.observations,
                maturity: periodEmerging.maturity
            )
            host.refreshAwarenessSnapshot()
            host.refreshPrimaryExplanation()
            host.recalculatePresence()
        } catch {
            environment.galaxyTimelineSections = []
            environment.deepSpaceTimelineSections = []
            environment.deepSpaceEntries = []
            environment.dayStats = .empty
            environment.memoryReadiness = .building
        }
    }

    // MARK: - Layer refresh

    private func refreshConnectorLayer(
        spans: [NoxActivitySpan],
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        range: (start: Date, end: Date),
        host: NoxContextMemoryPipelineHost
    ) async -> NoxConnectorContinuitySnapshot {
        let stored = (try? await connectorSignalStore.recentCadencePatterns()) ?? []
        let previousKind = host.ambientState.lastConnectorFocusKind.flatMap(NoxFocusBlockKind.init(rawValue:))
        let gapHours: Double
        if let started = host.ambientState.observationStartedAt {
            gapHours = max(0, Date().timeIntervalSince(started) / 3600)
        } else {
            gapHours = 0
        }

        return await NoxConnectorContinuityOrchestrator.refresh(
            preferences: host.preferences.connectors,
            stats: stats,
            focus: focus,
            spans: spans,
            range: range,
            storedPatterns: stored,
            recentDailyDensity: host.ambientState.recentConnectorDensities,
            previousFocusKind: previousKind,
            observationGapHours: gapHours,
            lastInterventionAt: host.ambientState.lastConnectorInterventionAt,
            signalStore: connectorSignalStore
        )
    }

    private func refreshBehavioralLayer(
        connectorSnapshot: NoxConnectorContinuitySnapshot,
        spans: [NoxActivitySpan],
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        threads: [NoxContinuityThread],
        semanticSpans: [NoxSemanticMemorySpan],
        arcs: [NoxSemanticArc],
        host: NoxContextMemoryPipelineHost,
        at date: Date
    ) async -> NoxBehavioralIntelligenceSnapshot {
        let weekly = (try? await memoryCoordinator.weeklyRollups(endingAt: date)) ?? []
        let monthly = (try? await memoryCoordinator.monthlyRollups(endingAt: date)) ?? []

        return await NoxBehavioralIntelligenceOrchestrator.refresh(
            paused: host.preferences.connectors.continuityEnrichmentPaused,
            connectorSnapshot: connectorSnapshot,
            stats: stats,
            focus: focus,
            spans: spans,
            threads: threads,
            arcs: arcs,
            weeklyRollups: weekly,
            monthlyRollups: monthly,
            recentDailyDensity: host.ambientState.recentConnectorDensities,
            lastInterventionAt: host.ambientState.lastConnectorInterventionAt,
            signalStore: behavioralSignalStore,
            at: date
        )
    }

    private func refreshAmbientUtilityLayer(
        connectorSnapshot: NoxConnectorContinuitySnapshot,
        behavioralSnapshot: NoxBehavioralIntelligenceSnapshot,
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        isUserIdle: Bool,
        previousDominantCategory: NoxActivityCategory?,
        host: NoxContextMemoryPipelineHost,
        at date: Date
    ) async -> NoxAmbientUtilitySnapshot {
        let base = NoxAmbientUtilityOrchestrator.refresh(
            paused: host.preferences.connectors.continuityEnrichmentPaused,
            preferences: host.preferences.ambientUtility,
            stats: stats,
            focus: focus,
            threads: threads,
            arcs: arcs,
            connectorSnapshot: connectorSnapshot,
            behavioralSnapshot: behavioralSnapshot,
            proposedIntervention: behavioralSnapshot.recommendedIntervention,
            lastNudgeAt: host.ambientState.lastContextualNudgeAt,
            ambientState: host.ambientState,
            at: date
        )
        var trust = host.ambientState.ambientTrust
        let (calibrated, _) = NoxAmbientUtilityCalibrationOrchestrator.calibrate(
            base: base,
            trust: &trust,
            threads: threads,
            arcs: arcs,
            stats: stats,
            focus: focus,
            behavioral: behavioralSnapshot,
            connectorSnapshot: connectorSnapshot,
            ambientState: host.ambientState,
            notificationsEnabled: host.preferences.ambientUtility.ambientNotificationsEnabled,
            at: date
        )
        host.ambientState.ambientTrust = trust

        guard !host.preferences.connectors.continuityEnrichmentPaused else {
            return calibrated
        }

        let context = NoxSystemContradictionContextBuilder.build(
            stats: stats,
            focus: focus,
            threads: threads,
            utility: calibrated,
            connectorSnapshot: connectorSnapshot,
            observationContinuitySeconds: host.signalTracker.observationContinuitySeconds(),
            isUserIdle: isUserIdle,
            previousDominantCategory: previousDominantCategory
        )
        var systemPersistence = host.ambientState.systemState
        let integrated = NoxSystemStateOrchestrator.integrate(
            utility: calibrated,
            behavioralIntervention: behavioralSnapshot.recommendedIntervention,
            context: context,
            preferences: host.preferences.ambientUtility.systemState,
            persistence: &systemPersistence,
            at: date
        )
        host.ambientState.systemState = systemPersistence
        host.environment?.systemTrayHint = integrated.trayHint
        return integrated.snapshot
    }

    private func refreshMemoryEvolutionLayer(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        behavioralSnapshot: NoxBehavioralIntelligenceSnapshot,
        utilitySnapshot: NoxAmbientUtilitySnapshot,
        focus: NoxFocusAnalysis?,
        host: NoxContextMemoryPipelineHost,
        at date: Date
    ) async -> NoxMemoryEvolutionSnapshot {
        guard !host.preferences.connectors.continuityEnrichmentPaused else {
            return .neutral
        }

        let typedMemories = (try? await memoryCoordinator.recentTypedMemories(limit: 40)) ?? []
        var evolutionState = host.ambientState.memoryEvolution
        let snapshot = NoxMemoryEvolutionOrchestrator.evolve(
            threads: threads,
            arcs: arcs,
            typedMemories: typedMemories,
            gravity: host.ambientState.ambientTrust.continuityGravity,
            behavioral: behavioralSnapshot,
            calibration: utilitySnapshot.calibration,
            focus: focus,
            stored: &evolutionState,
            calmnessAllowsResurfacing: resurfacingAllowed(utilitySnapshot: utilitySnapshot, host: host, at: date),
            at: date
        )
        host.ambientState.memoryEvolution = evolutionState
        return snapshot
    }

    private func resurfacingAllowed(
        utilitySnapshot: NoxAmbientUtilitySnapshot,
        host: NoxContextMemoryPipelineHost,
        at date: Date
    ) -> Bool {
        if let until = host.ambientState.systemState.resurfacingQuietUntil, date < until {
            return false
        }
        return utilitySnapshot.calmness.allowsResurfacing
    }

    private func deliverAmbientNotificationIfNeeded(
        _ candidate: NoxAmbientNotificationCandidate,
        host: NoxContextMemoryPipelineHost
    ) async {
        guard host.preferences.ambientUtility.ambientNotificationsEnabled else { return }
        guard await NoxAmbientNotificationEngine.requestAuthorizationIfNeeded() else { return }
        var state = host.ambientState
        await NoxAmbientNotificationEngine.deliver(candidate: candidate, ambientState: &state)
        host.ambientState = state
    }

    private func periodScopedEmergence(
        period: NoxMemoryPeriod,
        range: (start: Date, end: Date),
        threads: [NoxContinuityThread],
        stats: NoxMemoryDayStats,
        host: NoxContextMemoryPipelineHost
    ) async -> (observations: [NoxEmergingMemoryObservation], maturity: NoxMemoryMaturity) {
        let spans = (try? await memoryCoordinator.semanticSpans(from: range.start, to: range.end)) ?? []
        let includeLive = period == .today
        let result = NoxEmergingMemoryEngine.observe(
            semanticSpans: spans,
            openSpan: includeLive ? memoryCoordinator.currentOpenSemanticSpan : nil,
            threads: threads,
            stats: stats,
            liveSignalCount: includeLive ? host.liveBuffer.signals.count : 0,
            continuitySeconds: includeLive ? host.signalTracker.observationContinuitySeconds() : 0
        )
        return (result.observations, result.maturity)
    }

    private static func density(
        for stats: NoxMemoryDayStats,
        blockCount: Int,
        liveSignalCount: Int
    ) -> Double {
        let activityFactor = min(1.0, Double(stats.totalActiveMs) / Double(6 * 3_600_000))
        let blockFactor = min(1.0, Double(blockCount) / 24.0)
        let liveFactor = min(1.0, Double(liveSignalCount) / 12.0)
        return 0.35 + (activityFactor * 0.3) + (blockFactor * 0.15) + (liveFactor * 0.12)
    }

    private static func memoryReadiness(
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
}

/// Surface `NoxContextService` state to the memory pipeline without widening visibility across the app module.
@MainActor
protocol NoxContextMemoryPipelineHost: AnyObject {
    var environment: AppEnvironment? { get }
    var ambientState: NoxAmbientState { get set }
    var preferences: NoxAmbientPreferences { get }
    var continuityNote: String? { get }
    var latestFocusAnalysis: NoxFocusAnalysis? { get set }
    var liveBuffer: NoxLiveSignalBuffer { get }
    var signalTracker: NoxActivitySignalTracker { get }

    func syncDerivedEnvironmentState(
        memoryReadiness: NoxMemoryReadiness,
        emerging: [NoxEmergingMemoryObservation]?,
        maturity: NoxMemoryMaturity?
    )
    func refreshAwarenessSnapshot()
    func refreshPrimaryExplanation()
    func recalculatePresence()
}
