import Foundation

struct NoxContinuityStabilizationWindow {
    private var lastHardBundleId: String?
    private var traversals: [NoxEngagementState] = []
    private let mergeWindowSeconds: TimeInterval = 4.0

    mutating func recordTransient(_ state: NoxEngagementState) {
        traversals.append(state)
        traversals = traversals.suffix(8)
    }

    mutating func recordHardStabilization(_ state: NoxEngagementState) -> NoxContinuityMerge? {
        defer {
            lastHardBundleId = state.snapshot.bundleId
            traversals.removeAll()
        }

        guard lastHardBundleId == state.snapshot.bundleId, !traversals.isEmpty else {
            return nil
        }

        let total = traversals.reduce(0) { $0 + $1.foregroundDuration }
        let closeEnough = traversals.allSatisfy {
            state.foregroundStartedAt.timeIntervalSince($0.observedAt) <= mergeWindowSeconds
        }
        guard total <= mergeWindowSeconds, closeEnough else { return nil }

        return NoxContinuityMerge(
            bundleId: state.snapshot.bundleId,
            absorbedTraversalCount: traversals.count,
            totalTraversalSeconds: total
        )
    }
}
