import Foundation

/// Compresses and filters raw live signals before presentation layering.
enum NoxLiveSignalCompressor {
    private static let clusterWindow: TimeInterval = 150
    private static let semanticSuppressionWindow: TimeInterval = 180

    static func compress(
        _ signals: [NoxLiveSignal],
        semanticContext: NoxSemanticInference? = nil,
        contextLabel: String? = nil,
        maxVisible: Int = 8
    ) -> [NoxLiveSignal] {
        let presentation = NoxLiveContextPresenter.present(
            signals: signals,
            semanticContext: semanticContext,
            contextLabel: contextLabel,
            compact: maxVisible <= 3
        )
        var flat: [NoxLiveSignal] = []
        for item in presentation.pulse {
            flat.append(NoxLiveSignal(
                id: item.id,
                timestamp: item.timestamp,
                text: item.text,
                kind: .awareness,
                lifecycle: .transient(180)
            ))
        }
        for item in presentation.detail {
            flat.append(NoxLiveSignal(
                id: item.id,
                timestamp: Date(),
                text: item.text,
                kind: .app
            ))
        }
        return Array(flat.prefix(maxVisible))
    }

    static func shouldSuppressForPresentation(
        _ signal: NoxLiveSignal,
        in all: [NoxLiveSignal],
        semanticContext: NoxSemanticInference?
    ) -> Bool {
        shouldSuppress(signal, all: all, semanticContext: semanticContext)
    }

    // MARK: - Suppression

    private static func shouldSuppress(
        _ signal: NoxLiveSignal,
        all: [NoxLiveSignal],
        semanticContext: NoxSemanticInference?
    ) -> Bool {
        let text = signal.text.lowercased()

        if isTelemetryChatter(text) { return true }

        if signal.id.hasPrefix("semantic-"),
           text.contains("fragmented"),
           let semanticContext {
            switch semanticContext.state {
            case .passiveConsumption, .reading, .waiting:
                return true
            default:
                if semanticContext.browserCategory == .entertainment { return true }
            }
        }

        if signal.kind == .awareness,
           text.contains("watching quietly") || text.contains("stabilizing") || text.contains("settling") {
            return all.contains { $0.kind == .app || $0.kind == .window }
        }

        if hasRecentSemanticSignal(in: all, than: signal, within: semanticSuppressionWindow) {
            if signal.kind == .app { return true }
            if signal.kind == .idle { return true }
        }

        if let semanticContext,
           semanticContext.shouldSurface,
           semanticContext.confidence >= NoxSemanticConfidence.liveSignalThreshold,
           signal.kind == .app {
            return true
        }

        return false
    }

    private static func isTelemetryChatter(_ text: String) -> Bool {
        let blocked = [
            "activity resumed",
            "user idle",
            "user returned",
            "interaction active",
            "interaction idle",
            "typing started",
            "typing burst",
            "scroll activity",
            "mouse activity",
            "presence ·",
            "opened ",
            " window:",
            "window changed",
            "reading-heavy",
            "ai tool"
        ]
        return blocked.contains { text.contains($0) }
    }

    private static func hasRecentSemanticSignal(
        in signals: [NoxLiveSignal],
        than reference: NoxLiveSignal,
        within window: TimeInterval
    ) -> Bool {
        signals.contains { signal in
            guard isPulseCandidate(signal) else { return false }
            let delta = reference.timestamp.timeIntervalSince(signal.timestamp)
            return delta >= 0 && delta < window
        }
    }

    private static func isPulseCandidate(_ signal: NoxLiveSignal) -> Bool {
        signal.id.hasPrefix("semantic-") ||
            signal.id.hasPrefix("continuity-") ||
            signal.kind == .awareness
    }
}
