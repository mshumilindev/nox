import Foundation

@MainActor
final class NoxSemanticMemoryEngine {
    private var openSpan: NoxSemanticMemorySpan?
    private var lastInference: NoxSemanticInference?
    private let minimumSpanSeconds: TimeInterval = 32

    var currentOpenSpan: NoxSemanticMemorySpan? { openSpan }
    private let store: NoxSemanticMemoryStore

    init(store: NoxSemanticMemoryStore = NoxSemanticMemoryStore()) {
        self.store = store
    }

    func open() async throws {
        try await store.open()
    }

    @discardableResult
    func ingest(
        inference: NoxSemanticInference,
        appName: String?,
        bundleId: String?,
        context: NoxSemanticContext? = nil,
        at date: Date = Date()
    ) async throws -> NoxSemanticMemorySpan? {
        var closedSpan: NoxSemanticMemorySpan?
        guard !NoxSelfExclusion.isExcluded(bundleId: bundleId, appName: appName) else { return nil }

        if inference.sensitivityLevel == .privateContext || inference.sensitivityLevel == .sensitive {
            closedSpan = try await closeOpenSpanReturning(at: date, forceGeneric: true, inference: inference)
            try await openGenericSensitiveSpan(inference: inference, at: date)
            return closedSpan
        }

        guard inference.shouldSurface,
              inference.confidence >= NoxSemanticConfidence.memorySpanThreshold else {
            return nil
        }

        let title = NoxSemanticLabelCatalog.memoryTitle(inference: inference, appName: appName)
        let style = NoxSemanticLabelCatalog.liveSignalPhrase(from: inference)
            ?? inference.fusionPhrase
        let subtitle = NoxSemanticLabelCatalog.memorySubtitle(
            appNames: appName.map { [$0] } ?? []
        )

        if let open = openSpan,
           NoxSemanticSpanStitcher.shouldContinueOpenSpan(
               open,
               inference: inference,
               appName: appName,
               at: date,
               dominantContext: context?.dominantContextType
           ) {
            var apps = open.appNames
            if let appName, !apps.contains(appName) { apps.append(appName) }
            let metadata = NoxSemanticMemoryMetadata.build(
                inference: inference,
                context: context,
                appName: appName,
                bundleId: bundleId,
                appNames: apps
            )
            openSpan = NoxSemanticMemorySpan(
                id: open.id,
                startedAt: open.startedAt,
                endedAt: date,
                title: title,
                subtitle: NoxSemanticLabelCatalog.memorySubtitle(appNames: apps),
                interactionStyle: style,
                semanticState: inference.state,
                fusionLabel: inference.fusionLabel,
                sensitivityLevel: inference.sensitivityLevel,
                confidence: max(open.confidence, inference.confidence),
                appNames: apps,
                reasonsJson: encodeReasons(inference.reasons),
                metadataJson: metadata
            )
            lastInference = inference
            try await persistOpenSpan(open)
            return nil
        }

        if let open = openSpan {
            let duration = date.timeIntervalSince(open.startedAt)
            if duration >= minimumSpanSeconds {
                let closed = close(open, at: date)
                try await store.upsert(closed)
                closedSpan = closed
            } else {
                try await store.delete(id: open.id)
            }
        }

        let appNames = appName.map { [$0] } ?? []
        let metadata = NoxSemanticMemoryMetadata.build(
            inference: inference,
            context: context,
            appName: appName,
            bundleId: bundleId,
            appNames: appNames
        )
        openSpan = NoxSemanticMemorySpan(
            id: UUID().uuidString,
            startedAt: date,
            endedAt: nil,
            title: title,
            subtitle: subtitle,
            interactionStyle: style,
            semanticState: inference.state,
            fusionLabel: inference.fusionLabel,
            sensitivityLevel: inference.sensitivityLevel,
            confidence: inference.confidence,
            appNames: appNames,
            reasonsJson: encodeReasons(inference.reasons),
            metadataJson: metadata
        )
        lastInference = inference
        try await persistOpenSpan(openSpan)
        return closedSpan
    }

    func checkpointOpenSpan(at date: Date = Date()) async throws -> NoxSemanticMemorySpan? {
        guard let open = openSpan else { return nil }
        let duration = date.timeIntervalSince(open.startedAt)
        guard duration >= minimumSpanSeconds else {
            try await persistOpenSpan(open)
            return nil
        }
        let closed = close(open, at: date)
        try await store.upsert(closed)
        openSpan = nil
        return closed
    }

    func loadSpans(from start: Date, to end: Date, limit: Int = 24) async throws -> [NoxSemanticMemorySpan] {
        let raw = try await store.spans(from: start, to: end, limit: limit)
        return NoxSemanticSpanStitcher.stitch(raw)
    }

    func searchSpans(from start: Date, to end: Date, query: String) async throws -> [NoxSemanticMemorySpan] {
        let raw = try await store.searchSpans(from: start, to: end, query: query)
        return NoxSemanticSpanStitcher.stitch(raw)
    }

    private func closeOpenSpanReturning(
        at date: Date,
        forceGeneric: Bool,
        inference: NoxSemanticInference
    ) async throws -> NoxSemanticMemorySpan? {
        guard var open = openSpan else { return nil }
        open.endedAt = date
        if forceGeneric {
            open = NoxSemanticMemorySpan(
                id: open.id,
                startedAt: open.startedAt,
                endedAt: date,
                title: NoxSensitiveContextHandler.genericMemoryTitle(sensitivity: inference.sensitivityLevel),
                subtitle: "Generalized activity",
                interactionStyle: "Details not stored",
                semanticState: .unknown,
                fusionLabel: .unknown,
                sensitivityLevel: inference.sensitivityLevel,
                confidence: inference.confidence,
                appNames: [],
                reasonsJson: nil,
                metadataJson: nil
            )
        }
        try await store.upsert(open)
        openSpan = nil
        return open
    }

    private func openGenericSensitiveSpan(inference: NoxSemanticInference, at date: Date) async throws {
        let span = NoxSemanticMemorySpan(
            id: UUID().uuidString,
            startedAt: date,
            endedAt: date.addingTimeInterval(1),
            title: NoxSensitiveContextHandler.genericMemoryTitle(sensitivity: inference.sensitivityLevel),
            subtitle: "Generalized activity",
            interactionStyle: "Details not stored",
            semanticState: .unknown,
            fusionLabel: .unknown,
            sensitivityLevel: inference.sensitivityLevel,
            confidence: inference.confidence,
            appNames: [],
            reasonsJson: nil,
            metadataJson: nil
        )
        try await store.upsert(span)
    }

    private func persistOpenSpan(_ span: NoxSemanticMemorySpan?) async throws {
        guard let span else { return }
        try await store.upsert(span)
    }

    private func close(_ span: NoxSemanticMemorySpan, at date: Date) -> NoxSemanticMemorySpan {
        NoxSemanticMemorySpan(
            id: span.id,
            startedAt: span.startedAt,
            endedAt: date,
            title: span.title,
            subtitle: span.subtitle,
            interactionStyle: span.interactionStyle,
            semanticState: span.semanticState,
            fusionLabel: span.fusionLabel,
            sensitivityLevel: span.sensitivityLevel,
            confidence: span.confidence,
            appNames: span.appNames,
            reasonsJson: span.reasonsJson,
            metadataJson: span.metadataJson
        )
    }

    private func encodeReasons(_ reasons: [NoxSemanticReason]) -> String? {
        guard !reasons.isEmpty else { return nil }
        let payload = reasons.map { ["signal": $0.signal, "detail": $0.detail] }
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

enum NoxSemanticMemoryMetadata {
    static func build(
        inference: NoxSemanticInference,
        context: NoxSemanticContext?,
        appName: String?,
        bundleId: String?,
        appNames: [String] = []
    ) -> String? {
        guard inference.sensitivityLevel == .normal || inference.sensitivityLevel == .personal else {
            return nil
        }

        var payload: [String: Any] = [
            "schema_version": 1,
            "ui_title_source": "semantic_memory_span",
            "semantic_state": inference.state.rawValue,
            "semantic_confidence": inference.confidence,
            "fusion_label": inference.fusionLabel.rawValue,
            "fusion_confidence": inference.fusionConfidence,
            "sensitivity_level": inference.sensitivityLevel.rawValue,
            "should_surface": inference.shouldSurface,
            "reasons": inference.reasons.map { ["signal": $0.signal, "detail": $0.detail] }
        ]

        add(appName, key: "current_app_name", to: &payload)
        add(bundleId, key: "current_bundle_id", to: &payload)
        if !appNames.isEmpty {
            payload["span_app_names"] = appNames
        }
        add(inference.fusionPhrase, key: "fusion_phrase", to: &payload)
        add(inference.aiWorkflow?.rawValue, key: "ai_workflow", to: &payload)
        add(inference.aiWorkflowPhrase, key: "ai_workflow_phrase", to: &payload)

        guard let context else {
            return encode(payload)
        }

        add(context.appName, key: "observed_app_name", to: &payload)
        add(context.bundleId, key: "observed_bundle_id", to: &payload)
        add(context.windowTitle, key: "window_title", to: &payload)
        add(context.domain, key: "domain", to: &payload)
        payload["browser_category"] = context.browserCategory.rawValue
        payload["time_in_current_app_seconds"] = context.timeInCurrentApp
        payload["recent_switch_count"] = context.recentSwitchCount
        payload["is_user_idle"] = context.isUserIdle
        payload["idle_seconds"] = context.idleSeconds
        payload["nearby_bundle_ids"] = context.nearbyBundleIds
        payload["focus_hint"] = context.focusHint.rawValue
        payload["hour_of_day"] = context.hourOfDay
        payload["observation_continuity_seconds"] = context.observationContinuitySeconds
        payload["interaction"] = [
            "typing_density": context.metrics.typingDensity,
            "typing_active_seconds": context.metrics.typingActiveSeconds,
            "scroll_intensity": context.metrics.scrollIntensity,
            "mouse_density": context.metrics.mouseDensity,
            "is_interaction_active": context.metrics.isInteractionActive,
            "interaction_idle_seconds": context.metrics.interactionIdleSeconds
        ]

        return encode(payload)
    }

    private static func add(_ value: String?, key: String, to payload: inout [String: Any]) {
        guard let value, !value.isEmpty else { return }
        payload[key] = value
    }

    private static func encode(_ payload: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
