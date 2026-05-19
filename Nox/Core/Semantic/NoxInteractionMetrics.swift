import Foundation

/// Aggregated interaction metrics for a rolling window. No keystroke content.
struct NoxInteractionMetrics: Equatable, Sendable {
    var windowStartedAt: Date
    var windowSeconds: TimeInterval = 60

    var typingBurstCount: Int = 0
    var typingActiveSeconds: TimeInterval = 0
    var scrollEventCount: Int = 0
    var mouseEventCount: Int = 0
    var clickEstimateCount: Int = 0
    var isInteractionActive: Bool = false
    var interactionIdleSeconds: TimeInterval = 0
    var lastTypingAt: Date?
    var lastScrollAt: Date?
    var lastMouseAt: Date?

    var typingDensity: Double {
        guard windowMinutes > 0 else { return 0 }
        return Double(typingBurstCount) / windowMinutes
    }

    var scrollIntensity: Double {
        guard windowMinutes > 0 else { return 0 }
        return Double(scrollEventCount) / windowMinutes
    }

    var mouseDensity: Double {
        guard windowMinutes > 0 else { return 0 }
        return Double(mouseEventCount) / windowMinutes
    }

    var isWritingHeavy: Bool {
        typingDensity >= 2.5 || typingActiveSeconds >= 12
    }

    var isReadingHeavy: Bool {
        scrollIntensity >= 3 && typingDensity < 1.2
    }

    var isPassive: Bool {
        !isInteractionActive && typingDensity < 0.5 && scrollIntensity < 1
    }

    private var windowMinutes: Double {
        max(0.5, windowSeconds / 60)
    }
}

@MainActor
final class NoxInteractionMetricsAggregator {
    private var metrics = NoxInteractionMetrics(windowStartedAt: Date())
    private let windowDuration: TimeInterval = NoxRetentionPolicyDefaults.hot.interactionWindowSeconds

    func ingest(event: NoxEvent, at date: Date = Date()) {
        rollWindowIfNeeded(at: date)
        switch event.type {
        case .typingStarted:
            metrics.lastTypingAt = date
        case .typingBurst:
            metrics.typingBurstCount += 1
            metrics.typingActiveSeconds += 3
            metrics.lastTypingAt = date
        case .scrollActivity:
            metrics.scrollEventCount += 1
            metrics.lastScrollAt = date
        case .mouseActivity:
            metrics.mouseEventCount += 1
            metrics.lastMouseAt = date
        case .interactionActive:
            metrics.isInteractionActive = true
            metrics.interactionIdleSeconds = 0
        case .interactionIdle:
            metrics.isInteractionActive = false
        default:
            break
        }
    }

    func tickIdle(seconds: TimeInterval) {
        if !metrics.isInteractionActive {
            metrics.interactionIdleSeconds = seconds
        }
    }

    func snapshot(at date: Date = Date()) -> NoxInteractionMetrics {
        rollWindowIfNeeded(at: date)
        var copy = metrics
        copy.windowSeconds = date.timeIntervalSince(metrics.windowStartedAt)
        return copy
    }

    func resetForContextShift(at date: Date = Date()) {
        metrics = NoxInteractionMetrics(windowStartedAt: date)
    }

    /// Clears stale typing accumulation when pipeline detects passive playback.
    func applyPassivePlaybackMode() {
        metrics.typingBurstCount = 0
        metrics.typingActiveSeconds = 0
        metrics.isInteractionActive = false
    }

    private func rollWindowIfNeeded(at date: Date) {
        guard date.timeIntervalSince(metrics.windowStartedAt) >= windowDuration else { return }
        metrics = NoxInteractionMetrics(windowStartedAt: date)
    }
}
