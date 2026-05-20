import AppKit
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

/// Ensures SF Symbol names used in UI exist on this macOS version.
nonisolated enum NoxSFSymbol {
    static func validated(_ name: String, fallback: String = "circle.fill") -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return validated(fallback, fallback: "circle.fill") }
        if NSImage(systemSymbolName: trimmed, accessibilityDescription: nil) != nil {
            return trimmed
        }
        if trimmed != fallback {
            return validated(fallback, fallback: "circle.fill")
        }
        return "circle.fill"
    }
}
