import Foundation
import NoxSemanticCore
import NoxMemoryCore
import NoxContextCore
import NoxCore

public enum NoxTransientTraversalFilter {
    static let defaultTransientCeiling: TimeInterval = 1.5

    static func isTransient(
        duration: TimeInterval,
        interactionStrength: Double,
        intent: NoxForegroundIntent,
        nextSnapshot: NoxActivitySnapshot?
    ) -> Bool {
        let ceiling = intent.requiresLongerStabilization ? 2.2 : defaultTransientCeiling
        guard duration < ceiling else { return false }
        guard interactionStrength < 0.18 else { return false }
        guard nextSnapshot != nil else { return false }
        return true
    }

    static func interactionStrength(from metrics: NoxInteractionMetrics) -> Double {
        let typing = min(1, metrics.typingDensity / 5.0)
        let typingBurst = min(1, metrics.typingActiveSeconds / 6.0)
        let scrolling = min(1, metrics.scrollIntensity / 8.0)
        let mouse = min(1, metrics.mouseDensity / 20.0)
        let active = metrics.isInteractionActive ? 0.35 : 0
        return min(1, max(typing, typingBurst, scrolling, mouse) + active)
    }
}
