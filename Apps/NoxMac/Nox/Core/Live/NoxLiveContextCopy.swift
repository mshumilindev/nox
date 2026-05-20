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

/// Calm, human-facing copy for live context detail — not raw telemetry labels.
nonisolated enum NoxLiveContextCopy {

    static func displayText(for event: NoxEvent) -> String {
        switch event.payload {
        case .appChanged(let payload):
            if let previous = payload.previousAppName, previous != payload.appName {
                return "\(previous) → \(payload.appName)"
            }
            return payload.appName
        case .windowChanged(let payload):
            return payload.appName
        case .idle:
            return event.type == .userIdleStarted ? "Quiet period" : NoxHumanContextCopy.backInMotion
        case .session(let payload):
            if event.type == .sessionStarted {
                return "\(payload.primaryApp) — sustained stretch"
            }
            return "\(payload.primaryApp) stretch ended"
        case .presence:
            return ""
        case .permission(let payload):
            if payload.mode == NoxPermissionMode.appOnly.rawValue {
                return "Context awareness active"
            }
            if payload.mode == NoxPermissionMode.limited.rawValue {
                return "Limited context"
            }
            return "Additional context available"
        case .system(let payload):
            return payload.message
        case .interaction:
            return ""
        }
    }

    static func calmDetail(from rawSignalText: String) -> String? {
        let lower = rawSignalText.lowercased()
        if lower.isEmpty { return nil }

        if lower.contains("user idle") { return "Quiet period" }
        if lower.contains("user returned") { return NoxHumanContextCopy.backInMotion }
        if lower.contains("activity resumed") { return NoxHumanContextCopy.backInMotion }
        if lower.hasPrefix("returned to ") {
            return NoxHumanContextCopy.backInMotion
        }
        if lower.hasPrefix("switched to ") {
            let app = String(rawSignalText.dropFirst("Switched to ".count))
            return app
        }
        if lower.hasSuffix(" active") {
            let app = String(rawSignalText.dropLast(" active".count))
            return "\(app) active"
        }
        if lower.contains("opened ") {
            return String(rawSignalText.dropFirst("Opened ".count))
        }
        if lower.contains("interaction") || lower.contains("typing") || lower.contains("scroll") {
            return nil
        }
        if lower.contains("presence ·") { return nil }
        return rawSignalText
    }

    static func appTrail(from appNames: [String]) -> String? {
        let trail = appNames.filter { !$0.isEmpty }
        guard trail.count >= 2 else {
            if trail.count == 1 { return trail[0] }
            return nil
        }
        return trail.joined(separator: " → ")
    }
}
