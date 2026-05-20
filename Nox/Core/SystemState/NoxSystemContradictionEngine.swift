import Foundation

nonisolated enum NoxSystemContradictionEngine {

    static func evaluate(
        system: NoxSystemStateSnapshot,
        context: NoxSystemContradictionContext,
        preferences: NoxSystemStatePreferences,
        at date: Date = Date()
    ) -> [NoxSystemContradiction] {
        guard preferences.contradictionSuggestionsEnabled else { return [] }

        var results: [NoxSystemContradiction] = []

        if let contradiction = sleepFocusDuringActiveWork(system: system, context: context, at: date) {
            results.append(contradiction)
        }
        if preferences.caffeinateSuggestionsEnabled,
           let contradiction = longSessionWithoutDisplayProtection(system: system, context: context, at: date) {
            results.append(contradiction)
        }
        if let contradiction = highInterruptionCostWithoutQuietState(system: system, context: context, at: date) {
            results.append(contradiction)
        }
        if let contradiction = recoveryWindowAfterLongFocus(system: system, context: context, at: date) {
            results.append(contradiction)
        }
        if let contradiction = batterySensitiveLongSession(system: system, context: context, at: date) {
            results.append(contradiction)
        }
        if let contradiction = contextMismatchAfterReturn(system: system, context: context, at: date) {
            results.append(contradiction)
        }

        return results.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Contradiction types

    private static func sleepFocusDuringActiveWork(
        system: NoxSystemStateSnapshot,
        context: NoxSystemContradictionContext,
        at date: Date
    ) -> NoxSystemContradiction? {
        guard system.focusReading == .doNotDisturb || system.focusReading == .focused else { return nil }
        guard activeWork(context, minimumSeconds: 20 * 60) else { return nil }
        guard context.interruptionCost < 0.82 else { return nil }
        guard interactionDensityHigh(context) else { return nil }

        let confidence = 0.68 + min(0.12, context.observationContinuitySeconds / 7200)
        return make(
            type: .sleepFocusDuringActiveWork,
            label: "Sleep Focus still appears active.",
            detail: "Recent activity suggests sustained work while a quiet Focus mode may still be on.",
            confidence: confidence,
            actions: [
                action(.openFocusSettings, title: "Open Focus settings", detail: "Review Focus in System Settings."),
                action(.dismiss, title: "Dismiss", detail: "Keep current system state.")
            ]
        )
    }

    private static func longSessionWithoutDisplayProtection(
        system: NoxSystemStateSnapshot,
        context: NoxSystemContradictionContext,
        at date: Date
    ) -> NoxSystemContradiction? {
        guard !system.displaySleepPrevented else { return nil }
        guard sustainedContinuity(context, minimumSeconds: 60 * 60) else { return nil }
        guard activeWork(context, minimumSeconds: 45 * 60) else { return nil }
        guard interactionDensityHigh(context) else { return nil }

        return make(
            type: .longSessionWithoutDisplayProtection,
            label: "Display sleep protection may help preserve this session.",
            detail: "A long active stretch is underway without display sleep prevention.",
            confidence: 0.72,
            actions: [
                action(.startCaffeinate30, title: "Protect for 30 minutes", detail: "Start Nox-managed display sleep prevention."),
                action(.startCaffeinate60, title: "Protect for 60 minutes", detail: "Start Nox-managed display sleep prevention."),
                action(.dismiss, title: "Dismiss", detail: "Leave display sleep unchanged.")
            ]
        )
    }

    private static func highInterruptionCostWithoutQuietState(
        system: NoxSystemStateSnapshot,
        context: NoxSystemContradictionContext,
        at date: Date
    ) -> NoxSystemContradiction? {
        guard context.interruptionCost >= 0.62 else { return nil }
        guard deepFocus(context) else { return nil }
        guard system.focusReading != .doNotDisturb, system.focusReading != .focused else { return nil }
        guard !context.preferSilence else { return nil }

        return make(
            type: .highInterruptionCostWithoutQuietState,
            label: "A quieter system state may help preserve this focus window.",
            detail: "Focus appears stable while system quiet modes are not clearly active.",
            confidence: 0.64 + context.interruptionCost * 0.12,
            actions: [
                action(.openFocusSettings, title: "Open Focus settings", detail: "Choose a Focus mode in System Settings."),
                action(.dismiss, title: "Dismiss", detail: "Keep current system state.")
            ]
        )
    }

    private static func recoveryWindowAfterLongFocus(
        system: NoxSystemStateSnapshot,
        context: NoxSystemContradictionContext,
        at date: Date
    ) -> NoxSystemContradiction? {
        guard context.recoveryWindow.isOpen || context.decompression.recoveryWindowOpen else { return nil }
        guard context.decompression.inDecompression || context.decompression.passiveCollapseLoop else { return nil }
        guard hadLongFocus(context) else { return nil }
        guard context.isUserIdle || context.decompression.passiveCollapseLoop else { return nil }

        return make(
            type: .recoveryWindowAfterLongFocus,
            label: "A quieter recovery window may have opened.",
            detail: "Activity intensity is easing after a longer focus stretch.",
            confidence: 0.61,
            actions: [
                action(.reduceResurfacingQuiet, title: "Quiet resurfacing briefly", detail: "Reduce active resurfacing for a short window."),
                action(.dismiss, title: "Dismiss", detail: "Keep current resurfacing behavior.")
            ]
        )
    }

    private static func batterySensitiveLongSession(
        system: NoxSystemStateSnapshot,
        context: NoxSystemContradictionContext,
        at date: Date
    ) -> NoxSystemContradiction? {
        guard let level = system.batteryLevel, level < 0.28 else { return nil }
        guard !system.isCharging, !system.onExternalPower else { return nil }
        guard sustainedContinuity(context, minimumSeconds: 40 * 60) else { return nil }
        guard activeWork(context, minimumSeconds: 25 * 60) else { return nil }

        return make(
            type: .batterySensitiveLongSession,
            label: "Battery may become a constraint during this session.",
            detail: "Power is limited while activity has remained sustained.",
            confidence: 0.66,
            actions: [
                action(.openBatterySettings, title: "Open Battery settings", detail: "Review power settings in System Settings."),
                action(.dismiss, title: "Dismiss", detail: "Continue without changing settings.")
            ]
        )
    }

    private static func contextMismatchAfterReturn(
        system: NoxSystemStateSnapshot,
        context: NoxSystemContradictionContext,
        at date: Date
    ) -> NoxSystemContradiction? {
        guard context.returningAfterAbsence else { return nil }
        guard system.focusReading == .doNotDisturb || system.focusReading == .focused else { return nil }
        guard let current = context.dominantCategory,
              let previous = context.previousDominantCategory,
              current != previous else { return nil }
        guard categoriesDifferStrongly(current, previous) else { return nil }

        return make(
            type: .contextMismatchAfterReturn,
            label: "System state may not match the current context.",
            detail: "A Focus mode from before the absence may still be active.",
            confidence: 0.63,
            actions: [
                action(.openFocusSettings, title: "Open Focus settings", detail: "Review Focus in System Settings."),
                action(.dismiss, title: "Dismiss", detail: "Keep current system state.")
            ]
        )
    }

    // MARK: - Helpers

    private static func make(
        type: NoxSystemContradictionType,
        label: String,
        detail: String,
        confidence: Double,
        actions: [NoxSystemActionCandidate]
    ) -> NoxSystemContradiction {
        NoxSystemContradiction(
            id: "system-\(type.rawValue)",
            type: type,
            label: NoxEmotionalSafetyCopy.sanitize(label),
            detail: NoxEmotionalSafetyCopy.sanitize(detail),
            confidence: min(1, max(0, confidence)),
            explainabilityDetail: NoxSystemContradictionPresenter.explainabilityDetail,
            actions: actions
        )
    }

    private static func action(
        _ kind: NoxSystemActionKind,
        title: String,
        detail: String
    ) -> NoxSystemActionCandidate {
        NoxSystemActionPermissionModel.candidate(
            kind: kind,
            title: title,
            detail: detail,
            contradictionType: nil
        )
    }

    private static func activeWork(_ context: NoxSystemContradictionContext, minimumSeconds: TimeInterval) -> Bool {
        if context.observationContinuitySeconds >= minimumSeconds { return true }
        if (context.focus?.uninterruptedMs ?? 0) >= Int(minimumSeconds * 1000) { return true }
        if context.stats.focusedMs >= Int(minimumSeconds * 1000) { return true }
        return productiveCategory(context.dominantCategory)
    }

    private static func sustainedContinuity(_ context: NoxSystemContradictionContext, minimumSeconds: TimeInterval) -> Bool {
        context.observationContinuitySeconds >= minimumSeconds
            || context.stats.totalActiveMs >= Int(minimumSeconds * 1000)
    }

    private static func interactionDensityHigh(_ context: NoxSystemContradictionContext) -> Bool {
        if context.stats.totalActiveMs >= 20 * 60_000 { return true }
        if (context.focus?.switchCount ?? context.stats.appSwitchCount) <= 14 { return true }
        return false
    }

    private static func deepFocus(_ context: NoxSystemContradictionContext) -> Bool {
        context.focus?.kind == .deepWork || context.focus?.kind == .focused
            || context.receptiveness.deepFocusStable
    }

    private static func hadLongFocus(_ context: NoxSystemContradictionContext) -> Bool {
        context.stats.longestFocusBlockMs >= 40 * 60_000
            || (context.focus?.uninterruptedMs ?? 0) >= 35 * 60_000
    }

    private static func productiveCategory(_ category: NoxActivityCategory?) -> Bool {
        guard let category else { return false }
        switch category {
        case .development, .research, .productivity, .creative:
            return true
        default:
            return false
        }
    }

    private static func categoriesDifferStrongly(
        _ lhs: NoxActivityCategory,
        _ rhs: NoxActivityCategory
    ) -> Bool {
        let productive: Set<NoxActivityCategory> = [.development, .research, .productivity, .creative]
        let passive: Set<NoxActivityCategory> = [.entertainment, .passive, .communication]
        if productive.contains(lhs) != productive.contains(rhs) { return true }
        if passive.contains(lhs) != passive.contains(rhs) { return true }
        return lhs != rhs
    }
}
