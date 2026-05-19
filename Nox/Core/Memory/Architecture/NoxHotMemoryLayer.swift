import Foundation

/// Documents and centralizes hot-layer (ephemeral) retention targets.
/// Hot memory exists for inference, not history.
enum NoxHotMemoryLayer {
    static let layer: NoxMemoryLayer = .hot
    static let policy = NoxRetentionPolicyDefaults.hot

    struct Policy: Sendable, Equatable {
        let interactionWindowSeconds: TimeInterval
        let liveSignalCapacity: Int
        let liveSignalMaxSeconds: TimeInterval
    }
}

enum NoxRetentionPolicyDefaults {
    static var hot: NoxHotMemoryLayer.Policy {
        let p = NoxMemoryRetentionPolicy.default
        return NoxHotMemoryLayer.Policy(
            interactionWindowSeconds: p.hotInteractionWindowSeconds,
            liveSignalCapacity: p.hotLiveSignalCapacity,
            liveSignalMaxSeconds: p.hotLiveSignalMaxSeconds
        )
    }
}
