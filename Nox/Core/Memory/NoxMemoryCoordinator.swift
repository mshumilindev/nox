import Foundation

@MainActor
final class NoxMemoryCoordinator {
    private let memoryStore = NoxMemoryStore()
    private let semanticStore = NoxSemanticMemoryStore()
    private let semanticEngine: NoxSemanticMemoryEngine
    private let continuityEngine: NoxContinuityEngine
    private let rollupStore = NoxMemoryRollupStore()
    private let typedMemoryStore = NoxTypedMemoryStore()
    private let reflectionStore = NoxReflectionStore()
    private let aggregator = NoxMemoryAggregator()
    private let focusEngine = NoxFocusInterruptionEngine()
    private let statistics = NoxBehavioralStatistics()
    private var maintenanceCoordinator: NoxMemoryMaintenanceCoordinator?

    init() {
        semanticEngine = NoxSemanticMemoryEngine(store: semanticStore)
        continuityEngine = NoxContinuityEngine()
    }

    func open() async throws {
        try await memoryStore.open()
        try await semanticEngine.open()
        try await continuityEngine.open()
        try await rollupStore.open()
        try await typedMemoryStore.open()
        try await reflectionStore.open()
    }

    var continuity: NoxContinuityEngine { continuityEngine }
    var currentOpenSemanticSpan: NoxSemanticMemorySpan? { semanticEngine.currentOpenSpan }

    func semanticSpans(
        from start: Date,
        to end: Date
    ) async throws -> [NoxSemanticMemorySpan] {
        try await semanticEngine.loadSpans(from: start, to: end)
            .filter { span in
                !span.appNames.contains { NoxSelfExclusion.isExcluded(bundleId: nil, appName: $0) }
            }
    }

    func clearRecentActivity(from start: Date, to end: Date) async throws -> Int {
        try await memoryStore.deleteSpans(inRange: start, to: end)
    }

    func clearAllSemanticMemory() async throws -> Int {
        try await semanticStore.deleteAll()
    }

    func clearAllContinuityThreads() async throws -> Int {
        try await continuityEngine.clearAllThreads()
    }

    func runMemoryMaintenance(
        timelineStore: NoxTimelineStore,
        sessionStore: NoxSessionStore,
        policy: NoxMemoryRetentionPolicy = .default
    ) async throws -> NoxMaintenanceReport {
        let maintenance = maintenanceCoordinator ?? NoxMemoryMaintenanceCoordinator(
            timelineStore: timelineStore,
            memoryStore: memoryStore,
            sessionStore: sessionStore,
            semanticStore: semanticStore,
            rollupStore: rollupStore,
            typedMemoryStore: typedMemoryStore,
            policy: policy
        )
        maintenanceCoordinator = maintenance
        try await maintenance.open()
        return try await maintenance.runMaintenanceIfNeeded()
    }

    func performRestartRecovery(
        sessionStore: NoxSessionStore,
        ambient: NoxAmbientState,
        currentBundleId: String?
    ) async throws -> NoxRestartRecoveryResult {
        try await NoxRestartRecovery.recover(
            sessionStore: sessionStore,
            memoryStore: memoryStore,
            ambient: ambient,
            currentBundleId: currentBundleId
        )
    }

    func recoverOrphanSpans(at date: Date) async throws -> Int {
        try await memoryStore.closeOpenSpans(at: date)
    }

    func checkpointOpenSpan(at date: Date) async throws {
        if let closed = aggregator.closeOpenSpan(at: date) {
            try await memoryStore.upsertSpan(closed)
        }
    }

    @discardableResult
    func ingestSemantic(
        inference: NoxSemanticInference,
        appName: String?,
        bundleId: String?,
        context: NoxSemanticContext? = nil
    ) async throws -> NoxContinuityResurfacing? {
        guard !NoxSelfExclusion.isExcluded(bundleId: bundleId, appName: appName) else { return nil }
        let closedSpan = try await semanticEngine.ingest(
            inference: inference,
            appName: appName,
            bundleId: bundleId,
            context: context
        )
        return try await continuityEngine.observe(
            inference: inference,
            closedSpan: closedSpan,
            appName: appName
        )
    }

    func checkpointSemanticSpan(at date: Date = Date()) async throws -> NoxSemanticMemorySpan? {
        try await semanticEngine.checkpointOpenSpan(at: date)
    }

    func ingestSnapshot(_ snapshot: NoxActivitySnapshot) async throws {
        guard !NoxSelfExclusion.shouldIgnore(snapshot: snapshot) else { return }
        if let span = aggregator.ingestSnapshot(snapshot) {
            try await memoryStore.upsertSpan(span)
        }
    }

    func ingestAppChange(
        from previous: NoxActivitySnapshot?,
        to current: NoxActivitySnapshot
    ) async throws {
        if NoxSelfExclusion.shouldIgnore(snapshot: current) {
            if let previous, !NoxSelfExclusion.shouldIgnore(snapshot: previous) {
                try await closeSpanForTransition(from: previous, at: current.capturedAt)
            }
            return
        }
        if let previous, NoxSelfExclusion.shouldIgnore(snapshot: previous) {
            try await ingestSnapshot(current)
            return
        }
        let result = aggregator.ingestAppChange(from: previous, to: current, at: current.capturedAt)
        if let closed = result.closedSpan {
            try await memoryStore.upsertSpan(closed)
        }
        if let interruption = result.interruption {
            try await memoryStore.insertInterruption(interruption)
        }
        if let open = aggregator.openSpan {
            try await memoryStore.upsertSpan(open)
        }
    }

    func activitySpans(period: NoxMemoryPeriod) async throws -> [NoxActivitySpan] {
        let range = period.dateRange()
        let spans = try await memoryStore.spans(from: range.start, to: range.end)
        return spans.filter {
            !NoxSelfExclusion.isExcluded(bundleId: $0.bundleId, appName: $0.appName)
        }
    }

    func loadView(
        period: NoxMemoryPeriod,
        query: NoxMemoryQuery
    ) async throws -> (
        sections: [NoxTimelineSection],
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis,
        continuityThreads: [NoxContinuityThread]
    ) {
        let range = period.dateRange()
        var spans = try await memoryStore.spans(from: range.start, to: range.end)
        spans = spans.filter {
            !NoxSelfExclusion.isExcluded(bundleId: $0.bundleId, appName: $0.appName)
        }
        var semanticSpans = try await semanticEngine.loadSpans(from: range.start, to: range.end)
            .filter { span in
                !span.appNames.contains { NoxSelfExclusion.isExcluded(bundleId: nil, appName: $0) }
            }

        var interruptions = try await memoryStore.interruptions(from: range.start, to: range.end)
        var continuityThreads: [NoxContinuityThread] = []

        if NoxMemorySearchScope.isActive(query: query, period: period) {
            spans = try await memoryStore.searchSpans(
                from: range.start,
                to: range.end,
                query: query.normalizedText
            )
            semanticSpans = try await semanticEngine.searchSpans(
                from: range.start,
                to: range.end,
                query: query.normalizedText
            )
            let windows = NoxTimelineActivityDeduper.unionTimeWindows(
                activitySpans: spans,
                semanticSpans: semanticSpans
            )
            interruptions = interruptions.filter {
                NoxMemorySearchScope.interruptionMatches($0, query: query.normalizedText)
            }
            try await continuityEngine.runDecayPass(at: range.end)
            let loadedThreads = try await continuityEngine.loadThreads(from: range.start, to: range.end)
            continuityThreads = loadedThreads.filter {
                NoxMemorySearchScope.continuityMatches($0, query: query.normalizedText, windows: windows)
            }
        } else {
            try await continuityEngine.runDecayPass(at: range.end)
            continuityThreads = try await continuityEngine.loadThreads(from: range.start, to: range.end)
        }

        let analysis = focusEngine.analyze(spans: spans, interruptions: interruptions, range: range)
        try await memoryStore.clearFocusBlocks(from: range.start, to: range.end)
        for block in analysis.blocks {
            try await memoryStore.insertFocusBlock(block)
        }
        var storedBlocks = try await memoryStore.focusBlocks(from: range.start, to: range.end)

        if NoxMemorySearchScope.isActive(query: query, period: period) {
            let windows = NoxTimelineActivityDeduper.unionTimeWindows(
                activitySpans: spans,
                semanticSpans: semanticSpans
            )
            storedBlocks = storedBlocks.filter { NoxMemorySearchScope.focusMatches($0, windows: windows) }
            if storedBlocks.isEmpty {
                storedBlocks = analysis.blocks.filter { NoxMemorySearchScope.focusMatches($0, windows: windows) }
            }
        }
        let sections = NoxTimelineBlockPresenter.makeSections(
            spans: spans,
            focusBlocks: storedBlocks.isEmpty ? analysis.blocks : storedBlocks,
            interruptions: interruptions,
            semanticSpans: semanticSpans,
            continuityThreads: continuityThreads
        )
        let stats = statistics.compute(
            period: period,
            spans: spans,
            focusBlocks: storedBlocks.isEmpty ? analysis.blocks : storedBlocks,
            interruptions: interruptions
        )
        return (sections, stats, analysis.live, continuityThreads)
    }

    func loadReflectiveContinuity(
        period: NoxMemoryPeriod,
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        continuityThreads: [NoxContinuityThread],
        continuityNote: String?,
        lastShutdownAt: Date?,
        lastMorningAt: Date?,
        lastResurfacingShownAt: Date?,
        liveSignalCount: Int,
        continuitySeconds: TimeInterval,
        connectorSnapshot: NoxConnectorContinuitySnapshot = .empty,
        at date: Date = Date()
    ) async throws -> NoxReflectiveContinuityBundle {
        let lookback = date.addingTimeInterval(-14 * 24 * 3600)
        let semanticSpans = try await semanticEngine.loadSpans(from: lookback, to: date)
        let typedMemories = try await typedMemoryStore.recent(limit: 40)
        let weekly = try await rollupStore.rollups(
            level: .weekly,
            from: date.addingTimeInterval(-56 * 24 * 3600),
            to: date
        )
        let monthly = try await rollupStore.rollups(
            level: .monthly,
            from: date.addingTimeInterval(-120 * 24 * 3600),
            to: date
        )

        return try await NoxReflectiveContinuityAssembler.assemble(
            period: period,
            threads: continuityThreads,
            semanticSpans: semanticSpans,
            openSpan: semanticEngine.currentOpenSpan,
            stats: stats,
            focus: focus,
            typedMemories: typedMemories,
            weeklyRollups: weekly,
            monthlyRollups: monthly,
            reflectionStore: reflectionStore,
            continuityNote: continuityNote,
            lastShutdownAt: lastShutdownAt,
            lastMorningAt: lastMorningAt,
            lastResurfacingShownAt: lastResurfacingShownAt,
            liveSignalCount: liveSignalCount,
            continuitySeconds: continuitySeconds,
            connectorSnapshot: connectorSnapshot,
            at: date
        )
    }

    private func closeSpanForTransition(from previous: NoxActivitySnapshot, at date: Date) async throws {
        _ = previous
        if let closed = aggregator.closeOpenSpan(at: date) {
            try await memoryStore.upsertSpan(closed)
        }
    }

    private func mergeSemanticSpans(
        _ base: [NoxSemanticMemorySpan],
        _ extra: [NoxSemanticMemorySpan]
    ) -> [NoxSemanticMemorySpan] {
        var seen = Set(base.map(\.id))
        var merged = base
        for span in extra where !seen.contains(span.id) {
            seen.insert(span.id)
            merged.append(span)
        }
        return merged.sorted { $0.startedAt > $1.startedAt }
    }
}
