import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

/// Conceptual memory tiers. Nox remembers meaning, not microscopic replay.
public enum NoxMemoryLayer: String, Sendable, CaseIterable {
    /// Ephemeral inference inputs — seconds to minutes, mostly in-memory.
    case hot
    /// Short-term timeline / recent transitions — days to weeks.
    case warm
    /// Durable semantic structures — months to indefinite.
    case cold
}
