import Foundation

/// Splits live context into semantic pulse (primary) and raw detail (secondary).
enum NoxLiveContextPresenter {
    private static let detailWindow: TimeInterval = 240
    private static let pulseDedupWindow: TimeInterval = 12

    static func present(
        signals: [NoxLiveSignal],
        semanticContext: NoxSemanticInference? = nil,
        contextLabel: String? = nil,
        compact: Bool = false
    ) -> NoxLiveContextPresentation {
        let filtered = signals.filter { !NoxLiveSignalCompressor.shouldSuppressForPresentation($0, in: signals, semanticContext: semanticContext) }

        var pulse = pipelinePulse(contextLabel: contextLabel)
        pulse.append(contentsOf: extractPulse(
            from: filtered,
            semanticContext: semanticContext,
            contextLabel: contextLabel,
            compact: compact,
            excludingKeys: Set(pulse.map { normalizePulseKey($0.text) })
        ))
        let detail = extractDetail(from: filtered, excludingPulse: pulse, compact: compact)

        if pulse.isEmpty,
           let semanticContext,
           let title = NoxSemanticLabelCatalog.semanticPulseTitle(from: semanticContext) {
            let contextualTitle = contextualPulseTitle(base: title, inference: semanticContext, contextLabel: contextLabel)
            pulse = [
                NoxLivePulseItem(
                    id: "pulse-current",
                    text: contextualTitle,
                    timestamp: Date(),
                    symbolName: pulseSymbol(for: contextualTitle)
                )
            ]
        }

        return NoxLiveContextPresentation(
            pulse: Array(uniquePulseItems(pulse).prefix(compact ? 1 : 2)),
            detail: Array(detail.prefix(compact ? 1 : 3))
        )
    }

    // MARK: - Pulse

    private static func pipelinePulse(contextLabel: String?) -> [NoxLivePulseItem] {
        guard let contextLabel,
              isPipelineDominantLabel(contextLabel) else { return [] }
        return [
            NoxLivePulseItem(
                id: "pulse-pipeline",
                text: contextLabel,
                timestamp: Date(),
                symbolName: pulseSymbol(for: contextLabel)
            )
        ]
    }

    private static func extractPulse(
        from signals: [NoxLiveSignal],
        semanticContext: NoxSemanticInference?,
        contextLabel: String?,
        compact: Bool,
        excludingKeys: Set<String> = []
    ) -> [NoxLivePulseItem] {
        var items: [NoxLivePulseItem] = []
        var seenKeys = excludingKeys

        for signal in signals where isPulseCandidate(signal) {
            guard let title = pulseTitle(for: signal) else { continue }
            let key = normalizePulseKey(title)
            if seenKeys.contains(key) { continue }
            if let last = items.first, signal.timestamp.timeIntervalSince(last.timestamp) < pulseDedupWindow {
                if normalizePulseKey(last.text) == normalizePulseKey(title) { continue }
            }
            seenKeys.insert(key)
            items.append(
                NoxLivePulseItem(
                    id: signal.id,
                    text: title,
                    timestamp: signal.timestamp,
                    symbolName: pulseSymbol(for: title)
                )
            )
        }

        if let semanticContext,
           let title = NoxSemanticLabelCatalog.semanticPulseTitle(from: semanticContext),
           semanticContext.confidence >= NoxSemanticConfidence.liveSignalThreshold {
            var contextualTitle = contextualPulseTitle(
                base: title,
                inference: semanticContext,
                contextLabel: contextLabel
            )
            if let override = pipelinePulseOverride(
                inference: semanticContext,
                contextLabel: contextLabel
            ) {
                contextualTitle = override
            }
            let key = normalizePulseKey(contextualTitle)
            if shouldLetCurrentContextDominate(semanticContext) || isPipelineDominantLabel(contextLabel) {
                items = items.filter {
                    let itemKey = normalizePulseKey($0.text)
                    if itemKey.contains("fragmented"), !key.contains("fragmented") { return false }
                    return itemKey == key
                }
                seenKeys = Set(items.map { normalizePulseKey($0.text) })
            }
            if !seenKeys.contains(key) {
                items.insert(
                    NoxLivePulseItem(
                        id: "pulse-inference",
                        text: contextualTitle,
                        timestamp: Date(),
                        symbolName: pulseSymbol(for: contextualTitle)
                    ),
                    at: 0
                )
            }
        } else if let contextLabel, isPipelineDominantLabel(contextLabel) {
            let key = normalizePulseKey(contextLabel)
            if !seenKeys.contains(key) {
                items.insert(
                    NoxLivePulseItem(
                        id: "pulse-pipeline",
                        text: contextLabel,
                        timestamp: Date(),
                        symbolName: pulseSymbol(for: contextLabel)
                    ),
                    at: 0
                )
            }
        }

        return items
    }

    private static func pipelinePulseOverride(
        inference: NoxSemanticInference,
        contextLabel: String?
    ) -> String? {
        guard let contextLabel,
              isPipelineDominantLabel(contextLabel),
              inference.state == .fragmentedInteraction else { return nil }
        return contextLabel
    }

    private static func isPipelineDominantLabel(_ label: String?) -> Bool {
        guard let label else { return false }
        let knownPrefixes = [
            "Reading", "Writing", "Watching", "Listening", "Messages",
            "Creative work", "Playing", "File transfer", "Shopping research",
            "Travel planning", "Research", "Development context", "Focused in",
            "Passive viewing", "Browsing", "Mixed context", "Context settling",
            "Fragmented attention", "Several contexts"
        ]
        return knownPrefixes.contains { label.hasPrefix($0) || label.contains($0) }
    }

    private static func contextualPulseTitle(
        base: String,
        inference: NoxSemanticInference,
        contextLabel: String?
    ) -> String {
        guard let subject = normalizedSubject(contextLabel),
              inference.sensitivityLevel == .normal || inference.sensitivityLevel == .personal else {
            return base
        }

        let baseKey = normalizePulseKey(base)
        let subjectKey = normalizePulseKey(subject)
        if baseKey == subjectKey || baseKey.contains(subjectKey) || subjectKey.contains(baseKey) {
            return base
        }

        switch inference.fusionLabel {
        case .likelyPassiveEntertainment:
            return "Watching \(subject)"
        case .likelyGaming:
            return "Playing \(subject)"
        case .likelyFileTransfer:
            return "File transfer · \(subject)"
        case .likelyCreativeWork:
            return "Creative work · \(subject)"
        case .likelyTravelPlanning:
            return "Travel planning · \(subject)"
        case .likelyShopping:
            return "Shopping research · \(subject)"
        case .likelyResearch:
            return "Research browsing · \(subject)"
        default:
            if inference.state == .passiveConsumption { return "Watching \(subject)" }
            if inference.state == .reading { return "Reading \(subject)" }
            return base
        }
    }

    private static func normalizedSubject(_ value: String?) -> String? {
        guard var value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        value = value.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        guard value.count >= 3 else { return nil }
        if value.lowercased().contains("private activity") ||
            value.lowercased().contains("sensitive") ||
            value.lowercased().contains("personal browsing") {
            return nil
        }
        if value.count > 54 {
            value = String(value.prefix(51)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
        }
        return value
    }

    private static func isPulseCandidate(_ signal: NoxLiveSignal) -> Bool {
        if signal.id.hasPrefix("semantic-") || signal.id.hasPrefix("continuity-") { return true }
        if signal.text.lowercased().contains("resumed") { return true }
        if signal.kind == .awareness { return true }
        return false
    }

    private static func pulseTitle(for signal: NoxLiveSignal) -> String? {
        let text = signal.text.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        if text.lowercased().contains("passive viewing") { return nil }
        if text.lowercased().contains("stabilizing") { return nil }
        return NoxSemanticLabelCatalog.normalizePulseTitle(text)
    }

    private static func normalizePulseKey(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: " resumed", with: "")
            .replacingOccurrences(of: " period", with: "")
            .replacingOccurrences(of: " session", with: "")
            .replacingOccurrences(of: " continuity", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private static func uniquePulseItems(_ items: [NoxLivePulseItem]) -> [NoxLivePulseItem] {
        var seen = Set<String>()
        var result: [NoxLivePulseItem] = []

        for item in items {
            let key = normalizePulseKey(item.text)
            guard seen.insert(key).inserted else { continue }
            result.append(item)
        }

        return result
    }

    private static func shouldLetCurrentContextDominate(_ inference: NoxSemanticInference) -> Bool {
        if inference.confidence >= NoxSemanticConfidence.liveSignalThreshold {
            return true
        }
        if inference.sensitivityLevel == .sensitive || inference.sensitivityLevel == .privateContext {
            return true
        }
        switch inference.browserCategory {
        case .entertainment, .travel, .shopping, .reviews:
            return true
        default:
            switch inference.fusionLabel {
            case .likelyFileTransfer, .likelyGaming, .likelyCreativeWork, .likelyCommunication,
                    .likelyInteractiveBrowsing:
                return true
            default:
                return inference.state == .passiveConsumption || inference.state == .comparisonActivity
            }
        }
    }

    // MARK: - Detail

    private static func extractDetail(
        from signals: [NoxLiveSignal],
        excludingPulse: [NoxLivePulseItem],
        compact: Bool
    ) -> [NoxLiveDetailItem] {
        var items: [NoxLiveDetailItem] = []
        let cutoff = Date().addingTimeInterval(-detailWindow)

        let appSignals = signals.filter { $0.kind == .app && $0.timestamp >= cutoff }
        if let trail = buildAppTrail(from: appSignals), !trail.isEmpty {
            items.append(NoxLiveDetailItem(id: "trail-apps", text: trail, symbolName: "app.connected.to.app.below.fill"))
        }

        for signal in signals {
            guard signal.timestamp >= cutoff else { continue }
            guard signal.kind == .idle || signal.kind == .session || signal.kind == .permission else { continue }
            guard let calm = NoxLiveContextCopy.calmDetail(from: signal.text) else { continue }
            if items.contains(where: { $0.text == calm }) { continue }
            if excludingPulse.contains(where: { calm.lowercased().contains($0.text.lowercased()) }) { continue }
            items.append(NoxLiveDetailItem(id: signal.id, text: calm, symbolName: detailSymbol(for: signal.kind, text: calm)))
        }

        return items
    }

    private static func pulseSymbol(for text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("private") || lower.contains("sensitive") { return "lock.shield" }
        if lower.contains("watching") || lower.contains("passive") || lower.contains("viewing") {
            return "play.rectangle"
        }
        if lower.contains("playing") || lower.contains("game") { return "gamecontroller" }
        if lower.contains("reading") || lower.contains("research") { return "book" }
        if lower.contains("writing") { return "pencil.line" }
        if lower.contains("travel") { return "map" }
        if lower.contains("shopping") { return "bag" }
        if lower.contains("file transfer") { return "arrow.down.circle" }
        if lower.contains("creative") { return "paintpalette" }
        if lower.contains("messages") || lower.contains("conversation") {
            return "bubble.left.and.bubble.right"
        }
        if lower.contains("interactive browsing") { return "cursorarrow.click" }
        if lower.contains("fragmented") || lower.contains("several contexts") || lower.contains("mixed") {
            return "arrow.triangle.branch"
        }
        if lower.contains("development context") { return "hammer" }
        if lower.contains("focused in") { return "scope" }
        if lower.contains("quiet") || lower.contains("pause") { return "moon" }
        if lower.contains("continuity") || lower.contains("resumed") { return "link" }
        return "sparkles"
    }

    private static func detailSymbol(for kind: NoxLiveSignalKind, text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("→") { return "app.connected.to.app.below.fill" }
        if lower.contains("quiet") { return "moon" }
        if lower.contains("back in motion") || lower.contains("active again") { return "waveform.path" }
        switch kind {
        case .app, .window: return "app"
        case .idle: return "moon"
        case .session: return "clock"
        case .permission: return "lock.shield"
        case .system: return "desktopcomputer"
        case .awareness: return "sparkles"
        }
    }

    private static func buildAppTrail(from signals: [NoxLiveSignal]) -> String? {
        let names = signals.reversed().compactMap { signal -> String? in
            guard let calm = NoxLiveContextCopy.calmDetail(from: signal.text) else { return nil }
            if calm.hasSuffix(" active") {
                return String(calm.dropLast(" active".count))
            }
            if calm.contains("→") {
                return calm.components(separatedBy: " → ").last
            }
            return calm
        }
        var trail: [String] = []
        for name in names {
            if trail.last != name { trail.append(name) }
        }
        return NoxLiveContextCopy.appTrail(from: trail)
    }
}
