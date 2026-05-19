import Foundation

/// Compresses memory through adaptive horizons, extracts typed entities, then prunes warm noise.
@MainActor
final class NoxMemoryMaintenanceCoordinator {
    private let timelineStore: NoxTimelineStore
    private let memoryStore: NoxMemoryStore
    private let sessionStore: NoxSessionStore
    private let semanticStore: NoxSemanticMemoryStore
    private let rollupStore: NoxMemoryRollupStore
    private let typedMemoryStore: NoxTypedMemoryStore
    private let focusEngine = NoxFocusInterruptionEngine()
    private let pruningService: NoxMemoryPruningService
    private let policy: NoxMemoryRetentionPolicy

    private var lastMaintenanceAt: Date?

    init(
        timelineStore: NoxTimelineStore,
        memoryStore: NoxMemoryStore,
        sessionStore: NoxSessionStore,
        semanticStore: NoxSemanticMemoryStore,
        rollupStore: NoxMemoryRollupStore,
        typedMemoryStore: NoxTypedMemoryStore,
        policy: NoxMemoryRetentionPolicy = .default
    ) {
        self.timelineStore = timelineStore
        self.memoryStore = memoryStore
        self.sessionStore = sessionStore
        self.semanticStore = semanticStore
        self.rollupStore = rollupStore
        self.typedMemoryStore = typedMemoryStore
        self.policy = policy
        self.pruningService = NoxMemoryPruningService(policy: policy)
    }

    func open() async throws {
        try await rollupStore.open()
        try await typedMemoryStore.open()
    }

    func runMaintenanceIfNeeded(at date: Date = Date()) async throws -> NoxMaintenanceReport {
        if let lastMaintenanceAt,
           date.timeIntervalSince(lastMaintenanceAt) < policy.maintenanceIntervalSeconds {
            return .empty
        }
        let report = try await runMaintenance(at: date)
        lastMaintenanceAt = date
        return report
    }

    func runMaintenance(at date: Date = Date()) async throws -> NoxMaintenanceReport {
        let hourly = try await generateHourlyRollups(before: date)
        let daily = try await generateDailyRollups(before: date)
        let weekly = try await generateHorizonRollup(level: .weekly, before: date)
        let monthly = try await generateHorizonRollup(level: .monthly, before: date)
        let quarterly = try await generateHorizonRollup(level: .quarterly, before: date)
        let yearly = try await generateHorizonRollup(level: .yearly, before: date)
        let era = try await generateEraRollups(before: date)
        let typed = try await extractTypedMemories()

        return NoxMaintenanceReport(
            hourlyRollupsCreated: hourly,
            dailyRollupsCreated: daily,
            weeklyRollupsCreated: weekly,
            monthlyRollupsCreated: monthly,
            quarterlyRollupsCreated: quarterly,
            yearlyRollupsCreated: yearly,
            eraRollupsCreated: era,
            typedMemoriesCreated: typed,
            timelineEventsPruned: try await pruningService.pruneWarmTimeline(using: timelineStore, at: date),
            interruptionsPruned: try await pruningService.pruneWarmInterruptions(using: memoryStore, at: date),
            spansPruned: try await pruningService.pruneCompressedSpans(
                using: memoryStore,
                rollupStore: rollupStore,
                at: date
            ),
            focusBlocksPruned: try await pruningService.pruneDetailFocusBlocks(using: memoryStore, at: date),
            rollupsPruned: try await pruningService.pruneExpiredRollups(using: rollupStore, at: date)
        )
    }

    // MARK: - Hourly

    private func generateHourlyRollups(before date: Date) async throws -> Int {
        let hours = NoxRollupPeriodCalendar.completedHours(
            lookbackHours: policy.hourlyRollupLookbackHours,
            before: date
        )
        var created = 0
        for hour in hours {
            let range = NoxRollupPeriodCalendar.hourRange(containing: hour)
            if try await rollupStore.exists(level: .hourly, periodStart: range.start) { continue }
            let spans = try await memoryStore.spans(from: range.start, to: range.end)
            guard !spans.isEmpty else { continue }
            let facts = NoxHorizonFactsBuilder.buildHourly(spans: spans, at: range)
            let snapshot = NoxDeterministicRollupEngine.makeSnapshot(
                level: .hourly,
                periodStart: range.start,
                periodEnd: range.end,
                facts: facts,
                sourceCounts: ["spans": spans.count]
            )
            try await rollupStore.upsert(snapshot)
            created += 1
        }
        return created
    }

    // MARK: - Daily

    private func generateDailyRollups(before date: Date) async throws -> Int {
        let days = NoxRollupPeriodCalendar.completedDays(
            lookbackDays: policy.dailyRollupLookbackDays,
            before: date
        )
        var created = 0

        for day in days {
            let range = NoxRollupPeriodCalendar.dayRange(for: day)
            if try await rollupStore.exists(level: .daily, periodStart: range.start) { continue }

            let spans = try await memoryStore.spans(from: range.start, to: range.end)
            guard !spans.isEmpty else { continue }

            let sessions = try await sessions(in: range)
            let semantic = try await semanticStore.spans(from: range.start, to: range.end)
            let interruptions = try await memoryStore.interruptions(from: range.start, to: range.end)
            let focusBlocks = focusEngine.analyze(
                spans: spans.filter { !$0.category.excludedFromAnalysis },
                interruptions: interruptions,
                range: (range.start, range.end)
            ).blocks

            let facts = NoxDeterministicRollupEngine.buildDailyFacts(
                spans: spans,
                sessions: sessions,
                semanticSpans: semantic,
                interruptions: interruptions,
                focusBlocks: focusBlocks
            )

            let snapshot = NoxDeterministicRollupEngine.makeSnapshot(
                level: .daily,
                periodStart: range.start,
                periodEnd: range.end,
                facts: facts,
                sourceCounts: [
                    "spans": spans.count,
                    "sessions": sessions.count,
                    "semantic": semantic.count
                ]
            )
            try await rollupStore.upsert(snapshot)
            created += 1
        }
        return created
    }

    // MARK: - Higher horizons

    private func generateHorizonRollup(
        level: NoxMemoryCompressionLevel,
        before date: Date
    ) async throws -> Int {
        guard let childLevel = level.childLevel else { return 0 }

        let anchorDate: Date
        switch level {
        case .weekly: anchorDate = date.addingTimeInterval(-7 * 86_400)
        case .monthly: anchorDate = date.addingTimeInterval(-30 * 86_400)
        case .quarterly: anchorDate = date.addingTimeInterval(-90 * 86_400)
        case .yearly: anchorDate = date.addingTimeInterval(-365 * 86_400)
        default: return 0
        }

        let range = NoxRollupPeriodCalendar.periodRange(for: level, containing: anchorDate)
        if try await rollupStore.exists(level: level, periodStart: range.start) { return 0 }

        let children = try await rollupStore.rollups(level: childLevel, from: range.start, to: range.end)
        guard children.count >= minimumChildRollups(for: level) else { return 0 }

        let facts = NoxDeterministicRollupEngine.aggregateFacts(
            level: level,
            from: children.map(\.facts)
        )
        let snapshot = NoxDeterministicRollupEngine.makeSnapshot(
            level: level,
            periodStart: range.start,
            periodEnd: range.end,
            facts: facts,
            sourceCounts: ["child_rollups": children.count]
        )
        try await rollupStore.upsert(snapshot)
        return 1
    }

    private func generateEraRollups(before date: Date) async throws -> Int {
        let lookbackStart = date.addingTimeInterval(-Double(policy.dailyRollupLookbackDays) * 86_400)
        let monthly = try await rollupStore.rollups(level: .monthly, from: lookbackStart, to: date)
        let candidates = NoxEraDetector.detectEraCandidates(from: monthly)
        var created = 0

        for candidate in candidates {
            let range = NoxRollupPeriodCalendar.eraRange(start: candidate.periodStart, end: candidate.periodEnd)
            let eraID = "era-\(Int(range.start.timeIntervalSince1970))-\(Int(range.end.timeIntervalSince1970))"
            if try await rollupStore.exists(level: .era, periodStart: range.start) { continue }

            var facts = NoxRollupFacts()
            facts.eraLabel = candidate.label
            facts.eraThemes = candidate.themes
            facts.childRollupCount = monthly.filter {
                $0.periodStart >= range.start && $0.periodEnd <= range.end
            }.count

            let snapshot = NoxMemoryRollupSnapshot(
                id: eraID,
                level: .era,
                periodStart: range.start,
                periodEnd: range.end,
                generatedAt: Date(),
                version: 2,
                facts: facts,
                summaryText: NoxLayerNarrativeBuilder.build(facts: facts, level: .era),
                sourceCountsJson: nil
            )
            try await rollupStore.upsert(snapshot)
            created += 1
        }
        return created
    }

    private func extractTypedMemories() async throws -> Int {
        let recentRollups = try await rollupStore.rollups(
            level: .daily,
            from: Date().addingTimeInterval(-14 * 86_400),
            to: Date()
        )
        let existing = Set(try await typedMemoryStore.recent(limit: 500).map(\.id))
        var created = 0

        for rollup in recentRollups {
            let entities = NoxTypedMemoryExtractor.extract(from: rollup, existingIds: existing)
            for entity in entities where !existing.contains(entity.id) {
                try await typedMemoryStore.upsert(entity)
                created += 1
            }
        }
        return created
    }

    private func minimumChildRollups(for level: NoxMemoryCompressionLevel) -> Int {
        switch level {
        case .weekly: 3
        case .monthly: 2
        case .quarterly: 2
        case .yearly: 2
        case .era: 2
        default: 1
        }
    }

    private func sessions(in range: (start: Date, end: Date)) async throws -> [NoxWorkSession] {
        let recent = try await sessionStore.recentSessions(limit: 200)
        return recent.filter { session in
            session.startedAt >= range.start && session.startedAt < range.end
                && !NoxSelfExclusion.isExcluded(bundleId: session.primaryBundleId, appName: session.primaryApp)
        }
    }
}
