import Foundation

struct NoxWanderingAggregationEngine {
    private var traversalStartedAt: Date?
    private var traversalCount = 0
    private var recentBundles: [String] = []

    mutating func observe(_ state: NoxEngagementState) -> NoxEngagementState? {
        if state.phase == .hardStabilized {
            reset()
            return nil
        }

        guard state.phase == .transientTraversal || state.phase == .rawForeground else {
            return nil
        }

        traversalStartedAt = traversalStartedAt ?? state.foregroundStartedAt
        traversalCount += state.phase == .transientTraversal ? 1 : 0
        recentBundles.append(state.snapshot.bundleId)
        recentBundles = recentBundles.suffix(8)

        let elapsed = state.observedAt.timeIntervalSince(traversalStartedAt ?? state.observedAt)
        let distinct = Set(recentBundles).count
        guard elapsed >= 8, traversalCount >= 4, distinct >= 3 else { return nil }

        return NoxEngagementState(
            phase: .wandering,
            snapshot: state.snapshot,
            foregroundStartedAt: traversalStartedAt ?? state.foregroundStartedAt,
            observedAt: state.observedAt,
            foregroundDuration: elapsed,
            interactionStrength: state.interactionStrength,
            intent: state.intent,
            debugReason: "wandering: \(traversalCount) transient traversals across \(distinct) apps"
        )
    }

    mutating func reset() {
        traversalStartedAt = nil
        traversalCount = 0
        recentBundles.removeAll()
    }
}
