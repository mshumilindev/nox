import Foundation
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

// TODO(platform): move to mac adapter package when NoxRetentionPolicyDefaults stays in MemoryCore.
@MainActor
final class NoxInteractionMetricsAggregator {
    private var metrics = NoxInteractionMetrics(windowStartedAt: Date())
    private let windowDuration: TimeInterval = 60

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
