import Foundation

@MainActor
enum NoxConnectorContinuityOrchestrator {

    static func refresh(
        preferences: NoxConnectorPreferences,
        stats: NoxMemoryDayStats,
        focus: NoxFocusAnalysis?,
        spans: [NoxActivitySpan],
        range: (start: Date, end: Date),
        storedPatterns: [NoxCadencePattern],
        recentDailyDensity: [Double],
        previousFocusKind: NoxFocusBlockKind?,
        observationGapHours: Double,
        lastInterventionAt: Date?,
        signalStore: NoxConnectorSignalStore,
        at date: Date = Date()
    ) async -> NoxConnectorContinuitySnapshot {
        guard !preferences.continuityEnrichmentPaused else {
            return .empty
        }

        var generalized: [NoxGeneralizedSignal] = []
        var pressure: [NoxPressureSignal] = []
        var contributed: [NoxConnectorKind] = []
        var calendarProfile = NoxCalendarDayProfile.empty
        let calendarAccess = NoxCalendarContextProvider.accessState()

        if preferences.calendarEnabled, calendarAccess == .authorized {
            calendarProfile = NoxCalendarContextProvider.dayProfile(for: date)
            generalized += NoxCalendarEventClassifier.generalizedSignals(profile: calendarProfile, at: date)
            pressure += NoxCalendarPressureAnalyzer.pressureSignals(profile: calendarProfile, at: date)
            contributed.append(.calendar)
        }

        let communicationCadence = NoxCommunicationCadenceModel.snapshot(
            spans: spans,
            range: range,
            at: date
        )

        if preferences.communicationPressureEnabled {
            let comm = NoxCommunicationPressureEngine.analyze(
                cadence: communicationCadence,
                stats: stats,
                focus: focus,
                at: date
            )
            generalized += comm.signals
            pressure += comm.pressure
            contributed.append(.communication)
        }

        let workMinutes = spans
            .filter { $0.category.isWorkLike }
            .reduce(0) { $0 + max(0, $1.durationMs / 60_000) }

        let calendarSignals = generalized.filter { $0.kind == .calendar }
        let cadencePatterns = NoxCadenceEngine.build(
            stats: stats,
            workMinutes: workMinutes,
            focus: focus,
            calendarSignals: calendarSignals,
            communicationCadence: communicationCadence,
            storedPatterns: storedPatterns,
            recentDailyDensity: recentDailyDensity,
            at: date
        )
        if !cadencePatterns.isEmpty { contributed.append(.cadence) }

        let overloadSignals = NoxRecoveryInferenceEngine.overloadSignals(
            stats: stats,
            focus: focus,
            calendarProfile: calendarProfile,
            pressureSignals: pressure,
            at: date
        )
        if !overloadSignals.isEmpty { contributed.append(.recovery) }

        let latestCategories = spans.suffix(6).map(\.category)
        let transitions = NoxTransitionEngine.detect(
            focus: focus,
            stats: stats,
            overloadSignals: overloadSignals,
            calendarSignals: calendarSignals,
            previousFocusKind: previousFocusKind,
            observationGapHours: observationGapHours,
            latestCategories: latestCategories,
            at: date
        )
        if !transitions.isEmpty { contributed.append(.transition) }

        let intervention = NoxAmbientInterventionEngine.evaluate(
            transitions: transitions,
            cadencePatterns: cadencePatterns,
            overloadSignals: overloadSignals,
            calendarSignals: calendarSignals,
            lastInterventionAt: lastInterventionAt,
            at: date
        )

        let explainability = NoxConnectorExplainability.summary(
            preferences: preferences,
            calendarAccess: calendarAccess,
            contributed: contributed
        )

        let snapshot = NoxConnectorContinuitySnapshot(
            generalizedSignals: gate(generalized),
            pressureSignals: gatePressure(pressure),
            cadencePatterns: cadencePatterns,
            transitions: transitions,
            overloadSignals: overloadSignals,
            enrichmentNotes: [],
            explainability: explainability,
            intervention: intervention
        )

        try? await signalStore.appendCadencePatterns(cadencePatterns)

        return snapshot
    }

    private static func gate(_ signals: [NoxGeneralizedSignal]) -> [NoxGeneralizedSignal] {
        signals
            .filter { $0.confidence >= 0.6 }
            .sorted { $0.confidence > $1.confidence }
            .prefix(8)
            .map { $0 }
    }

    private static func gatePressure(_ signals: [NoxPressureSignal]) -> [NoxPressureSignal] {
        signals
            .filter { $0.confidence >= 0.6 }
            .sorted { $0.confidence > $1.confidence }
            .prefix(6)
            .map { $0 }
    }
}
