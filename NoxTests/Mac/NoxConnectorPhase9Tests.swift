import Foundation
import Testing
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
@testable import Nox

struct NoxConnectorPhase9Tests {

    @Test func calendarClassifierProducesGeneralizedLabels() {
        let profile = NoxCalendarDayProfile(
            eventCount: 6,
            meetingMinutes: 260,
            longestGapMinutes: 25,
            afternoonEventCount: 4,
            eveningEventCount: 2,
            backToBackBlocks: 3,
            hasTravelLikeStructure: false
        )
        let signals = NoxCalendarEventClassifier.generalizedSignals(profile: profile)
        #expect(signals.contains { $0.label.contains("dense") || $0.label.contains("coordination") })
        #expect(signals.allSatisfy { !$0.label.localizedCaseInsensitiveContains("meeting with") })
    }

    @Test func communicationPressureAvoidsInboxLanguage() {
        let cadence = NoxCommunicationCadenceSnapshot(
            communicationMinutes: 95,
            communicationSpanCount: 4,
            burstWindows: 2,
            quietMinutes: 10,
            responseHeavyScore: 0.7
        )
        let result = NoxCommunicationPressureEngine.analyze(
            cadence: cadence,
            stats: NoxMemoryDayStats(
                periodLabel: "Today",
                totalActiveMs: 3600_000,
                focusedMs: 1200_000,
                fragmentedMs: 900_000,
                appSwitchCount: 10,
                longestFocusBlockMs: 1800_000,
                dominantApp: "Mail",
                dominantCategory: .communication
            ),
            focus: nil
        )
        #expect(!result.signals.isEmpty || !result.pressure.isEmpty)
        let combined = result.signals.map(\.label) + result.pressure.map(\.label)
        #expect(combined.allSatisfy { !$0.localizedCaseInsensitiveContains("reply") })
    }

    @Test func interventionRespectsCooldown() {
        let intervention = NoxAmbientInterventionEngine.evaluate(
            transitions: [
                NoxTransitionEvent(
                    id: "t1",
                    kind: .returningAfterAbsence,
                    label: "Returning",
                    confidence: 0.8,
                    observedAt: Date()
                )
            ],
            cadencePatterns: [],
            overloadSignals: [],
            calendarSignals: [],
            lastInterventionAt: Date().addingTimeInterval(-1200)
        )
        #expect(intervention == nil)
    }

    @Test func recoveryCopyIsObservational() {
        let signals = NoxRecoveryInferenceEngine.overloadSignals(
            stats: NoxMemoryDayStats(
                periodLabel: "Today",
                totalActiveMs: 8 * 3600_000,
                focusedMs: 1000_000,
                fragmentedMs: 3 * 3600_000,
                appSwitchCount: 16,
                longestFocusBlockMs: 900_000,
                dominantApp: nil,
                dominantCategory: .development
            ),
            focus: NoxFocusAnalysis(kind: .fragmented, uninterruptedMs: 0, switchCount: 16, continuityScore: 0.2),
            calendarProfile: NoxCalendarDayProfile(
                eventCount: 5,
                meetingMinutes: 200,
                longestGapMinutes: 20,
                afternoonEventCount: 3,
                eveningEventCount: 0,
                backToBackBlocks: 2,
                hasTravelLikeStructure: false
            ),
            pressureSignals: [
                NoxPressureSignal(
                    id: "p1",
                    kind: .calendar,
                    label: "Elevated",
                    level: .elevated,
                    confidence: 0.8,
                    observedAt: Date()
                )
            ]
        )
        #expect(signals.allSatisfy { !$0.label.localizedCaseInsensitiveContains("burnout") })
    }

    @Test @MainActor func connectorOrchestratorHonorsPause() async {
        let store = NoxConnectorSignalStore()
        try? await store.open()
        let snapshot = await NoxConnectorContinuityOrchestrator.refresh(
            preferences: NoxConnectorPreferences(
                calendarEnabled: true,
                communicationPressureEnabled: true,
                continuityEnrichmentPaused: true
            ),
            stats: .empty,
            focus: nil,
            spans: [],
            range: (Date(), Date()),
            storedPatterns: [],
            recentDailyDensity: [],
            previousFocusKind: nil,
            observationGapHours: 0,
            lastInterventionAt: nil,
            signalStore: store
        )
        #expect(snapshot == .empty)
    }
}
