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

nonisolated enum NoxSystemContradictionSuppressionModel {

    static let globalCooldownSeconds: TimeInterval = 4 * 3600
    static let dismissalCooldownSeconds: TimeInterval = 12 * 3600
    static let minimumConfidence = 0.58

    static func eligible(
        _ contradictions: [NoxSystemContradiction],
        system: NoxSystemStateSnapshot,
        preferSilence: Bool,
        interruptionCost: Double,
        receptiveness: NoxInterventionReceptiveness,
        persistence: NoxSystemStatePersistence,
        at date: Date = Date()
    ) -> NoxSystemContradiction? {
        guard !contradictions.isEmpty else { return nil }
        if interruptionCost >= 0.88 { return nil }
        if receptiveness.interruptionSensitive, interruptionCost >= 0.78 { return nil }

        if let last = persistence.lastSystemInterventionAt,
           date.timeIntervalSince(last) < globalCooldownSeconds {
            return nil
        }

        for contradiction in contradictions {
            guard contradiction.confidence >= minimumConfidence else { continue }
            if preferSilence, contradiction.type != .recoveryWindowAfterLongFocus { continue }
            if requiresReliableFocus(contradiction.type), !system.focusAuthorized { continue }
            if let dismissed = persistence.dismissedContradictions[contradiction.type.rawValue],
               date.timeIntervalSince(dismissed) < dismissalCooldownSeconds {
                continue
            }
            return contradiction
        }
        return nil
    }

    static func recordDismissal(
        type: NoxSystemContradictionType,
        persistence: inout NoxSystemStatePersistence,
        at date: Date
    ) {
        persistence.dismissedContradictions[type.rawValue] = date
        trimDismissals(&persistence.dismissedContradictions, at: date)
    }

    static func recordShown(persistence: inout NoxSystemStatePersistence, at date: Date) {
        persistence.lastSystemInterventionAt = date
    }

    private static func requiresReliableFocus(_ type: NoxSystemContradictionType) -> Bool {
        switch type {
        case .sleepFocusDuringActiveWork, .highInterruptionCostWithoutQuietState, .contextMismatchAfterReturn:
            return true
        default:
            return false
        }
    }

    private static func trimDismissals(_ map: inout [String: Date], at date: Date) {
        map = map.filter { date.timeIntervalSince($0.value) < dismissalCooldownSeconds * 4 }
    }
}
