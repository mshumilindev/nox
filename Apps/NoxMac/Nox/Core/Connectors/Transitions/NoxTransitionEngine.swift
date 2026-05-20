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

enum NoxTransitionEngine {

    static func detect(
        focus: NoxFocusAnalysis?,
        stats: NoxMemoryDayStats,
        overloadSignals: [NoxOverloadSignal],
        calendarSignals: [NoxGeneralizedSignal],
        previousFocusKind: NoxFocusBlockKind?,
        observationGapHours: Double,
        latestCategories: [NoxActivityCategory],
        at date: Date = Date()
    ) -> [NoxTransitionEvent] {
        var events: [NoxTransitionEvent] = []

        if focus?.kind == .deepWork, previousFocusKind != .deepWork {
            events.append(event(
                id: "transition-deep-work",
                kind: .enteringDeepWork,
                label: "Entering deep work",
                confidence: 0.76,
                at: date
            ))
        }

        if previousFocusKind == .deepWork, focus?.kind != .deepWork {
            events.append(event(
                id: "transition-exit-focus",
                kind: .exitingSustainedFocus,
                label: "Exiting sustained focus",
                confidence: 0.72,
                at: date
            ))
        }

        if stats.fragmentedMs > stats.focusedMs && focus?.kind == .fragmented {
            events.append(event(
                id: "transition-fragmentation",
                kind: .abruptFragmentation,
                label: "Abrupt fragmentation",
                confidence: 0.7,
                at: date
            ))
        }

        if !overloadSignals.isEmpty {
            events.append(event(
                id: "transition-context-collapse",
                kind: .contextCollapse,
                label: "Context thins after dense activity",
                confidence: 0.68,
                at: date
            ))
        }

        if observationGapHours >= 8 {
            events.append(event(
                id: "transition-return",
                kind: .returningAfterAbsence,
                label: "Returning after time away",
                confidence: min(0.85, 0.5 + observationGapHours / 24.0),
                at: date
            ))
        }

        if stats.focusedMs < 30 * 60_000 && stats.totalActiveMs > 0 && stats.appSwitchCount <= 3 {
            events.append(event(
                id: "transition-recovery",
                kind: .beginningRecovery,
                label: "Beginning recovery behavior",
                confidence: 0.64,
                at: date
            ))
        }

        if let last = latestCategories.last,
           latestCategories.dropLast().contains(where: { $0.isWorkLike }),
           (last == .entertainment || last == .passive) {
            events.append(event(
                id: "transition-passive-media",
                kind: .workToPassiveMedia,
                label: "Shift from work to passive media",
                confidence: 0.66,
                at: date
            ))
        }

        if calendarSignals.contains(where: { $0.id == "calendar-travel-like" }) {
            events.append(event(
                id: "transition-travel-like",
                kind: .travelLikeShift,
                label: "Travel-mode-like behavior shift",
                confidence: 0.67,
                at: date
            ))
        }

        return events
            .sorted { $0.confidence > $1.confidence }
            .prefix(5)
            .map { $0 }
    }

    private static func event(
        id: String,
        kind: NoxTransitionKind,
        label: String,
        confidence: Double,
        at date: Date
    ) -> NoxTransitionEvent {
        NoxTransitionEvent(
            id: id,
            kind: kind,
            label: label,
            confidence: confidence,
            observedAt: date
        )
    }
}
