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
import NoxShrineCore

nonisolated enum NoxTimelinePresenter {
    static func displayText(for event: NoxEvent) -> String {
        let calm = NoxLiveContextCopy.displayText(for: event)
        if !calm.isEmpty { return calm }

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
        case .presence(let payload):
            return payload.current.capitalized
        case .permission:
            return "Context updated"
        case .system(let payload):
            return payload.message
        case .interaction:
            return ""
        }
    }

    static func subtitle(for event: NoxEvent) -> String? {
        switch event.payload {
        case .appChanged(let payload):
            let title = payload.windowTitle
            return title.flatMap { $0.isEmpty ? nil : $0 }
        case .windowChanged(let payload):
            return payload.appName
        case .session(let payload):
            return payload.primaryBundleId
        default:
            return nil
        }
    }
}

