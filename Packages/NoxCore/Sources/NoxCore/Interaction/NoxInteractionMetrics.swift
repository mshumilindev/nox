import Foundation

/// Aggregated interaction metrics for a rolling window. No keystroke content.
public struct NoxInteractionMetrics: Equatable, Sendable {
    public var windowStartedAt: Date
    public var windowSeconds: TimeInterval = 60

    public var typingBurstCount: Int = 0
    public var typingActiveSeconds: TimeInterval = 0
    public var scrollEventCount: Int = 0
    public var mouseEventCount: Int = 0
    public var clickEstimateCount: Int = 0
    public var isInteractionActive: Bool = false
    public var interactionIdleSeconds: TimeInterval = 0
    public var lastTypingAt: Date?
    public var lastScrollAt: Date?
    public var lastMouseAt: Date?

    public init(windowStartedAt: Date, windowSeconds: TimeInterval = 60) {
        self.windowStartedAt = windowStartedAt
        self.windowSeconds = windowSeconds
    }

    public var typingDensity: Double {
        guard windowMinutes > 0 else { return 0 }
        return Double(typingBurstCount) / windowMinutes
    }

    public var scrollIntensity: Double {
        guard windowMinutes > 0 else { return 0 }
        return Double(scrollEventCount) / windowMinutes
    }

    public var mouseDensity: Double {
        guard windowMinutes > 0 else { return 0 }
        return Double(mouseEventCount) / windowMinutes
    }

    public var isWritingHeavy: Bool {
        typingDensity >= 2.5 || typingActiveSeconds >= 12
    }

    public var isReadingHeavy: Bool {
        scrollIntensity >= 3 && typingDensity < 1.2
    }

    public var isPassive: Bool {
        !isInteractionActive && typingDensity < 0.5 && scrollIntensity < 1
    }

    private var windowMinutes: Double {
        max(0.5, windowSeconds / 60)
    }
}
