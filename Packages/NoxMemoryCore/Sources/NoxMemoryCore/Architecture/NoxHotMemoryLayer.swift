import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

/// Documents and centralizes hot-layer (ephemeral) retention targets.
/// Hot memory exists for inference, not history.
nonisolated public enum NoxHotMemoryLayer {
    public static let layer: NoxMemoryLayer = .hot
    public static let policy = NoxRetentionPolicyDefaults.hot

    public struct Policy: Sendable, Equatable {
        public let interactionWindowSeconds: TimeInterval
        public let liveSignalCapacity: Int
        public let liveSignalMaxSeconds: TimeInterval

        public init(
            interactionWindowSeconds: TimeInterval,
            liveSignalCapacity: Int,
            liveSignalMaxSeconds: TimeInterval
        ) {
            self.interactionWindowSeconds = interactionWindowSeconds
            self.liveSignalCapacity = liveSignalCapacity
            self.liveSignalMaxSeconds = liveSignalMaxSeconds
        }
    }
}

nonisolated public enum NoxRetentionPolicyDefaults {
    public static var hot: NoxHotMemoryLayer.Policy {
        let p = NoxMemoryRetentionPolicy.default
        return NoxHotMemoryLayer.Policy(
            interactionWindowSeconds: p.hotInteractionWindowSeconds,
            liveSignalCapacity: p.hotLiveSignalCapacity,
            liveSignalMaxSeconds: p.hotLiveSignalMaxSeconds
        )
    }
}
