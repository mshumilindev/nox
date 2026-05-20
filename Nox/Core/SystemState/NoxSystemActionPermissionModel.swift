import Foundation

nonisolated enum NoxSystemActionPermissionModel {

    static func candidate(
        kind: NoxSystemActionKind,
        title: String,
        detail: String,
        contradictionType: NoxSystemContradictionType?
    ) -> NoxSystemActionCandidate {
        let (safety, confirmation) = safety(for: kind)
        return NoxSystemActionCandidate(
            id: "action-\(kind.rawValue)",
            kind: kind,
            title: NoxEmotionalSafetyCopy.sanitize(title),
            detail: NoxEmotionalSafetyCopy.sanitize(detail),
            safetyLevel: safety,
            requiresConfirmation: confirmation,
            explainabilityReason: explainability(for: kind),
            fallbackWhenUnavailable: fallback(for: kind)
        )
    }

    static func allowed(
        _ kind: NoxSystemActionKind,
        preferences: NoxSystemStatePreferences,
        caffeinateActive: Bool
    ) -> Bool {
        switch kind {
        case .startCaffeinate30, .startCaffeinate60, .startCaffeinateUntilSessionEnd:
            return preferences.caffeinateSuggestionsEnabled && !caffeinateActive
        case .stopCaffeinate:
            return caffeinateActive
        case .openFocusSettings, .openBatterySettings, .dismiss, .reduceResurfacingQuiet:
            return true
        }
    }

    private static func safety(for kind: NoxSystemActionKind) -> (NoxSystemActionSafetyLevel, Bool) {
        switch kind {
        case .openFocusSettings, .openBatterySettings:
            return (.settingsOnly, false)
        case .startCaffeinate30, .startCaffeinate60, .startCaffeinateUntilSessionEnd, .stopCaffeinate:
            return (.userConfirmed, true)
        case .reduceResurfacingQuiet:
            return (.informational, false)
        case .dismiss:
            return (.informational, false)
        }
    }

    private static func explainability(for kind: NoxSystemActionKind) -> String {
        switch kind {
        case .openFocusSettings:
            return "Opens Focus settings for a manual review."
        case .openBatterySettings:
            return "Opens Battery settings for a manual review."
        case .startCaffeinate30, .startCaffeinate60, .startCaffeinateUntilSessionEnd:
            return "Starts Nox-managed display sleep prevention after you confirm."
        case .stopCaffeinate:
            return "Stops Nox-managed display sleep prevention."
        case .reduceResurfacingQuiet:
            return "Temporarily reduces active resurfacing inside Nox."
        case .dismiss:
            return "Dismisses this suggestion without changing system settings."
        }
    }

    private static func fallback(for kind: NoxSystemActionKind) -> String? {
        switch kind {
        case .openFocusSettings, .openBatterySettings:
            return "Open System Settings manually if the link is unavailable."
        default:
            return nil
        }
    }
}
