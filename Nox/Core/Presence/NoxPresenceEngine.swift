import Foundation

struct NoxPresenceEngine {
    func evaluate(context: NoxPresenceContext) -> NoxPresenceState {
        let capabilities = context.capabilities

        if !capabilities.appAwarenessAvailable {
            return .limited
        }

        if context.isUserIdle {
            return context.idleSeconds >= NoxPresenceRules.restingSeconds ? .resting : .idle
        }

        if !context.hasEnoughSignals {
            return .limited
        }

        let raw = evaluateActivity(context: context)

        return clamp(raw, ceiling: capabilities.awarenessTier.presenceCeiling)
    }

    private func evaluateActivity(context: NoxPresenceContext) -> NoxPresenceState {
        let capabilities = context.capabilities

        if !capabilities.allowsFocusStates {
            return evaluateAppOnlyActivity(context: context)
        }

        let bundleId = context.currentBundleId ?? ""
        let isProductive = NoxPresenceRules.isProductivityApp(
            bundleId: bundleId,
            windowTitle: context.currentWindowTitle
        )

        if context.focusAnalysis?.kind == .fragmented {
            return .distracted
        }

        if context.recentSwitchCount >= NoxPresenceRules.distractedSwitchCount {
            return .distracted
        }

        if isBehaviorallyQuiet(context: context) {
            return .quiet
        }

        guard isProductive else { return .active }

        if context.focusAnalysis?.kind == .deepWork {
            return .flow
        }

        if context.focusAnalysis?.kind == .focused {
            return .focused
        }

        if context.timeInCurrentApp >= NoxPresenceRules.flowSeconds,
           context.recentSwitchCount <= NoxPresenceRules.flowMaxSwitches {
            return .flow
        }

        if context.timeInCurrentApp >= NoxPresenceRules.focusedSeconds,
           context.recentSwitchCount <= NoxPresenceRules.focusedMaxSwitches {
            return .focused
        }

        return .active
    }

    private func evaluateAppOnlyActivity(context: NoxPresenceContext) -> NoxPresenceState {
        if isBehaviorallyQuiet(context: context) {
            return .quiet
        }
        return .active
    }

    /// Quiet = low engagement / passive observation — not a permission state.
    private func isBehaviorallyQuiet(context: NoxPresenceContext) -> Bool {
        context.recentSwitchCount == 0 &&
            context.timeInCurrentApp < 90 &&
            context.idleSeconds < 30
    }

    private func clamp(_ proposed: NoxPresenceState, ceiling: NoxPresenceState) -> NoxPresenceState {
        let order: [NoxPresenceState] = [
            .limited, .quiet, .idle, .resting, .active, .distracted, .focused, .flow
        ]
        guard let proposedIndex = order.firstIndex(of: proposed),
              let ceilingIndex = order.firstIndex(of: ceiling) else {
            return proposed
        }
        if proposedIndex <= ceilingIndex { return proposed }
        return ceiling
    }
}
