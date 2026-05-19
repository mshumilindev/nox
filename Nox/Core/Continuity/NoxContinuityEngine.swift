import Foundation

@MainActor
final class NoxContinuityEngine {
    private let store: NoxContinuityThreadStore
    private var lastResurfacingByThread: [String: Date] = [:]
    private var pendingResurfacing: NoxContinuityResurfacing?
    private let resurfacingCooldown: TimeInterval = 300

    init(store: NoxContinuityThreadStore = NoxContinuityThreadStore()) {
        self.store = store
    }

    func open() async throws {
        try await store.open()
    }

    func observe(
        inference: NoxSemanticInference,
        closedSpan: NoxSemanticMemorySpan?,
        appName: String?,
        at date: Date = Date()
    ) async throws -> NoxContinuityResurfacing? {
        guard !NoxSelfExclusion.isExcluded(bundleId: nil, appName: appName) else { return nil }

        if let closedSpan, closedSpan.durationMs >= 60_000 {
            let signature = NoxContinuitySignature.from(
                inference: inference,
                appNames: closedSpan.appNames,
                appName: appName
            )
            return try await attachSpan(closedSpan, inference: inference, signature: signature, at: date)
        }

        let appNames = appName.map { [$0] } ?? []
        let signature = NoxContinuitySignature.from(
            inference: inference,
            appNames: appNames,
            appName: appName
        )
        return try await detectResumption(signature: signature, inference: inference, at: date)
    }

    func loadThreads(from start: Date, to end: Date) async throws -> [NoxContinuityThread] {
        let raw = try await store.threads(from: start, to: end)
        return raw.map { NoxContinuityDecay.apply(to: $0, at: end) }
    }

    func runDecayPass(at date: Date = Date()) async throws {
        let lookback = date.addingTimeInterval(-60 * 24 * 3600)
        let candidates = try await store.activeCandidates(since: lookback, limit: 80)
        let updated = candidates.map { NoxContinuityDecay.apply(to: $0, at: date) }
        try await store.applyDecayUpdates(updated)
    }

    func consumePendingResurfacing() -> NoxContinuityResurfacing? {
        defer { pendingResurfacing = nil }
        return pendingResurfacing
    }

    func clearAllThreads() async throws -> Int {
        try await store.deleteAll()
    }

    // MARK: - Private

    private func attachSpan(
        _ span: NoxSemanticMemorySpan,
        inference: NoxSemanticInference,
        signature: NoxContinuitySignature,
        at date: Date
    ) async throws -> NoxContinuityResurfacing? {
        let lookback = date.addingTimeInterval(-30 * 24 * 3600)
        let candidates = try await store.activeCandidates(since: lookback).map {
            NoxContinuityDecay.apply(to: $0, at: date)
        }

        if let match = NoxContinuityMatcher.bestMatch(
            signature: signature,
            candidates: candidates,
            at: date,
            gapSinceLastActivity: candidates.first.map { date.timeIntervalSince($0.lastSeenAt) }
        ), match.totalScore >= NoxContinuityConfidence.attachThreshold,
           let existing = try await store.thread(id: match.threadId) {
            let merged = merge(existing: existing, span: span, signature: signature, match: match, at: date)
            try await store.upsert(merged)
            if match.isResumption {
                return emitResurfacing(for: merged, match: match, at: date)
            }
            return nil
        }

        let created = newThread(from: span, signature: signature, inference: inference, at: date)
        try await store.upsert(created)
        return nil
    }

    private func detectResumption(
        signature: NoxContinuitySignature,
        inference: NoxSemanticInference,
        at date: Date
    ) async throws -> NoxContinuityResurfacing? {
        guard inference.shouldSurface,
              inference.confidence >= NoxSemanticConfidence.memorySpanThreshold else {
            return nil
        }

        let lookback = date.addingTimeInterval(-14 * 24 * 3600)
        let candidates = try await store.activeCandidates(since: lookback).map {
            NoxContinuityDecay.apply(to: $0, at: date)
        }.filter { $0.decayState != .archived }

        guard let match = NoxContinuityMatcher.bestMatch(
            signature: signature,
            candidates: candidates,
            at: date,
            gapSinceLastActivity: nil
        ), match.isResumption,
           let existing = try await store.thread(id: match.threadId) else {
            return nil
        }

        var updated = existing
        updated.lastSeenAt = date
        updated.currentStatus = .resumed
        updated.totalResumptions += 1
        updated.lastResumedAt = date
        updated.confidence = NoxContinuityConfidence.accumulate(
            current: updated.confidence,
            matchScore: match.totalScore,
            sessionCount: updated.totalSessions
        )
        updated.supportingSignals = match.components
        updated.decayState = .active
        try await store.upsert(updated)
        return emitResurfacing(for: updated, match: match, at: date)
    }

    private func merge(
        existing: NoxContinuityThread,
        span: NoxSemanticMemorySpan,
        signature: NoxContinuitySignature,
        match: NoxContinuityMatchResult,
        at date: Date
    ) -> NoxContinuityThread {
        var apps = existing.dominantApps
        for name in span.appNames where !apps.contains(name) { apps.append(name) }
        var spanIds = existing.linkedSpanIds
        if !spanIds.contains(span.id) { spanIds.append(span.id) }
        var memoryIds = [span.id] + existing.recentMemoryIds.filter { $0 != span.id }
        memoryIds = Array(memoryIds.prefix(12))

        let sessions = existing.totalSessions + 1
        let resumptions = existing.totalResumptions + (match.isResumption ? 1 : 0)
        let duration = existing.totalActiveDurationMs + span.durationMs
        let confidence = NoxContinuityConfidence.accumulate(
            current: existing.confidence,
            matchScore: match.totalScore,
            sessionCount: sessions
        )
        let daysActive = max(
            1,
            Calendar.current.dateComponents([.day], from: existing.firstSeenAt, to: date).day ?? 1
        )
        let recurrence = NoxContinuityConfidence.recurrenceStrength(
            sessionCount: sessions,
            resumptionCount: resumptions,
            spanCount: spanIds.count,
            daysActive: daysActive
        )

        return NoxContinuityThread(
            id: existing.id,
            semanticType: signature.semanticType,
            title: displayTitle(for: signature.semanticType, span: span, sensitivity: span.sensitivityLevel),
            dominantApps: apps,
            dominantCategories: existing.dominantCategories,
            dominantDomains: existing.dominantDomains,
            continuitySignature: signature,
            firstSeenAt: existing.firstSeenAt,
            lastSeenAt: date,
            totalActiveDurationMs: duration,
            totalSessions: sessions,
            totalResumptions: resumptions,
            continuityStrength: NoxContinuityConfidence.continuityStrength(
                confidence: confidence,
                totalDurationMs: duration,
                recurrence: recurrence
            ),
            recurrenceStrength: recurrence,
            interruptionPattern: span.semanticState == .fragmentedInteraction ? "fragmented" : existing.interruptionPattern,
            currentStatus: match.isResumption ? .resumed : .active,
            recentMemoryIds: memoryIds,
            linkedSpanIds: spanIds,
            linkedSessionIds: existing.linkedSessionIds,
            supportingSignals: match.components,
            confidence: confidence,
            lastResumedAt: match.isResumption ? date : existing.lastResumedAt,
            temporalPatterns: updatedPatterns(existing.temporalPatterns, at: date),
            decayState: .active,
            sensitivityLevel: span.sensitivityLevel
        )
    }

    private func newThread(
        from span: NoxSemanticMemorySpan,
        signature: NoxContinuitySignature,
        inference: NoxSemanticInference,
        at date: Date
    ) -> NoxContinuityThread {
        NoxContinuityThread(
            id: UUID().uuidString,
            semanticType: signature.semanticType,
            title: displayTitle(for: signature.semanticType, span: span, sensitivity: span.sensitivityLevel),
            dominantApps: span.appNames,
            dominantCategories: [],
            dominantDomains: [],
            continuitySignature: signature,
            firstSeenAt: span.startedAt,
            lastSeenAt: date,
            totalActiveDurationMs: span.durationMs,
            totalSessions: 1,
            totalResumptions: 0,
            continuityStrength: inference.confidence,
            recurrenceStrength: 0.1,
            interruptionPattern: span.semanticState == .fragmentedInteraction ? "fragmented" : "steady",
            currentStatus: .active,
            recentMemoryIds: [span.id],
            linkedSpanIds: [span.id],
            linkedSessionIds: [],
            supportingSignals: [],
            confidence: inference.confidence,
            lastResumedAt: nil,
            temporalPatterns: updatedPatterns([], at: date),
            decayState: .active,
            sensitivityLevel: span.sensitivityLevel
        )
    }

    private func displayTitle(
        for type: NoxContinuitySemanticType,
        span: NoxSemanticMemorySpan,
        sensitivity: NoxSensitivityLevel
    ) -> String {
        if sensitivity != .normal {
            return "Private continuity"
        }
        if span.title.lowercased().contains("continuity") {
            return span.title
        }
        switch type {
        case .aiDevelopment: return "AI-assisted development continuity"
        case .research: return "Research continuity"
        case .travelPlanning: return "Travel planning continuity"
        case .writing: return "Writing continuity"
        case .development: return "Development continuity"
        case .fragmentedWorkflow: return "Fragmented attention"
        case .passiveViewing: return "Passive viewing continuity"
        case .privateContext, .sensitiveContext: return "Private continuity"
        case .general: return span.title
        }
    }

    private func emitResurfacing(
        for thread: NoxContinuityThread,
        match: NoxContinuityMatchResult?,
        at date: Date
    ) -> NoxContinuityResurfacing? {
        if let last = lastResurfacingByThread[thread.id],
           date.timeIntervalSince(last) < resurfacingCooldown {
            return nil
        }
        guard let resurfacing = NoxContinuityResurfacingPresenter.resurfacing(
            for: thread,
            match: match,
            at: date
        ) else { return nil }
        lastResurfacingByThread[thread.id] = date
        pendingResurfacing = resurfacing
        return resurfacing
    }

    private func updatedPatterns(_ existing: [String], at date: Date) -> [String] {
        let hour = Calendar.current.component(.hour, from: date)
        let bucket: String
        switch hour {
        case 5..<12: bucket = "morning"
        case 12..<17: bucket = "afternoon"
        case 17..<22: bucket = "evening"
        default: bucket = "night"
        }
        var patterns = existing
        if !patterns.contains(bucket) { patterns.append(bucket) }
        return Array(patterns.suffix(4))
    }
}
