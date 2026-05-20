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

struct NoxBehavioralIntelligencePhase10Tests {

    @Test func patternEngineGatesLowConfidence() {
        let signatures = NoxBehavioralPatternEngine.detect(
            stats: .empty,
            focus: nil,
            spans: [],
            connectorCadence: [],
            recentDailyDensity: [],
            weeklyRollups: []
        )
        #expect(signatures.allSatisfy { $0.confidence >= NoxPatternConfidenceModel.minimumDisplay })
    }

    @Test func driftCopyAvoidsAlarmLanguage() {
        let drift = NoxBehavioralDriftEngine.detect(
            recentDailyDensity: [0.7, 0.68, 0.65, 0.2, 0.18, 0.15],
            stats: NoxMemoryDayStats(
                periodLabel: "Today",
                totalActiveMs: 20 * 60_000,
                focusedMs: 5 * 60_000,
                fragmentedMs: 10 * 60_000,
                appSwitchCount: 4,
                longestFocusBlockMs: 600_000,
                dominantApp: nil,
                dominantCategory: .passive
            ),
            focus: nil,
            signatures: []
        )
        if let drift {
            let combined = "\(drift.label) \(drift.detail)".lowercased()
            #expect(!combined.contains("wrong"))
            #expect(!combined.contains("burnout"))
            #expect(!combined.contains("failing"))
        }
    }

    @Test func adaptiveInterventionSuppressesDuringDeepFocus() {
        let orchestration = NoxAmbientOrchestrationContext(
            signals: [
                NoxOrchestrationSignal(
                    id: "focus",
                    kind: .deepFocusStability,
                    level: 0.85,
                    note: "stable"
                )
            ],
            generatedAt: Date()
        )
        let base = NoxAmbientIntervention(
            id: "frag",
            label: "Fragmented day",
            detail: "Observed locally.",
            kind: .fragmentedDayAck,
            observedAt: Date()
        )
        let connector = NoxConnectorContinuitySnapshot(
            generalizedSignals: [],
            pressureSignals: [],
            cadencePatterns: [],
            transitions: [],
            overloadSignals: [],
            enrichmentNotes: [],
            explainability: .empty,
            intervention: base
        )
        let result = NoxAdaptiveInterventionTimingEngine.evaluate(
            connectorSnapshot: connector,
            orchestration: orchestration,
            signatures: [],
            drift: nil,
            lastInterventionAt: Date().addingTimeInterval(-7 * 3600)
        )
        #expect(result == nil)
    }

    @Test @MainActor func behavioralOrchestratorHonorsPause() async {
        let store = NoxBehavioralIntelligenceSignalStore()
        try? await store.open()
        let snapshot = await NoxBehavioralIntelligenceOrchestrator.refresh(
            paused: true,
            connectorSnapshot: .empty,
            stats: .empty,
            focus: nil,
            spans: [],
            threads: [],
            arcs: [],
            weeklyRollups: [],
            monthlyRollups: [],
            recentDailyDensity: [],
            lastInterventionAt: nil,
            signalStore: store
        )
        #expect(snapshot == .empty)
    }

    @Test func memoryPrioritizerOrdersByAdaptiveWeight() {
        func thread(
            id: String,
            title: String,
            strength: Double,
            recurrence: Double,
            resumptions: Int
        ) -> NoxContinuityThread {
            NoxContinuityThread(
                id: id,
                semanticType: .aiDevelopment,
                title: title,
                dominantApps: [],
                dominantCategories: [],
                dominantDomains: [],
                continuitySignature: NoxContinuitySignature(
                    ecosystemKey: id,
                    semanticType: .aiDevelopment,
                    appTokens: [],
                    semanticState: .writing,
                    fusionLabel: .likelyAIAssistedWork,
                    interactionProfile: "steady",
                    densityProfile: "moderate"
                ),
                firstSeenAt: Date(),
                lastSeenAt: Date(),
                totalActiveDurationMs: 3_600_000,
                totalSessions: 2,
                totalResumptions: resumptions,
                continuityStrength: strength,
                recurrenceStrength: recurrence,
                interruptionPattern: "steady",
                currentStatus: .active,
                recentMemoryIds: [],
                linkedSpanIds: [],
                linkedSessionIds: [],
                supportingSignals: [],
                confidence: 0.7,
                lastResumedAt: resumptions > 0 ? Date() : nil,
                temporalPatterns: [],
                decayState: .active,
                sensitivityLevel: .normal
            )
        }
        let threads = [
            thread(id: "a", title: "Alpha", strength: 0.4, recurrence: 0.2, resumptions: 0),
            thread(id: "b", title: "Beta", strength: 0.9, recurrence: 0.8, resumptions: 3)
        ]
        let weights = NoxAdaptiveContinuityModel.weights(
            threads: threads,
            arcs: [],
            signatures: []
        )
        let result = NoxContextualMemoryPrioritizer.prioritize(
            threads: threads,
            arcs: [],
            weights: weights,
            signatures: [],
            lifeStructures: [],
            drift: nil,
            existingNotes: []
        )
        #expect(result.threadIds.first == "b")
    }

    // MARK: - Phase 13: System state contradictions

    @Test func sleepFocusContradictionRequiresActiveWorkAndDND() {
        let system = NoxSystemStateSnapshot(
            focusReading: .doNotDisturb,
            focusAuthorized: true,
            displaySleepPrevented: false,
            noxCaffeinateActive: false,
            batteryLevel: 0.8,
            isCharging: true,
            onExternalPower: true,
            lowPowerModeEnabled: false,
            externalDisplayConnected: false,
            appearanceIsDark: true,
            hourOfDay: 14,
            signalsReliable: true
        )
        let stats = NoxMemoryDayStats(
            periodLabel: "Today",
            totalActiveMs: 35 * 60_000,
            focusedMs: 30 * 60_000,
            fragmentedMs: 0,
            appSwitchCount: 6,
            longestFocusBlockMs: 30 * 60_000,
            dominantApp: "Xcode",
            dominantCategory: .development
        )
        let context = phase13Context(stats: stats, continuitySeconds: 35 * 60)
        let results = NoxSystemContradictionEngine.evaluate(
            system: system,
            context: context,
            preferences: .default
        )
        #expect(results.contains { $0.type == .sleepFocusDuringActiveWork })

        let quietSystem = NoxSystemStateSnapshot(
            focusReading: .available,
            focusAuthorized: true,
            displaySleepPrevented: false,
            noxCaffeinateActive: false,
            batteryLevel: 0.8,
            isCharging: true,
            onExternalPower: true,
            lowPowerModeEnabled: false,
            externalDisplayConnected: false,
            appearanceIsDark: true,
            hourOfDay: 14,
            signalsReliable: true
        )
        let none = NoxSystemContradictionEngine.evaluate(
            system: quietSystem,
            context: context,
            preferences: .default
        )
        #expect(!none.contains { $0.type == .sleepFocusDuringActiveWork })
    }

    @Test func longSessionWithoutCaffeinateSurfacesWhenUnprotected() {
        let system = MockSystemStateProvider(stub: .unknown).snapshot(noxCaffeinateActive: false, at: Date())
        let stats = NoxMemoryDayStats(
            periodLabel: "Today",
            totalActiveMs: 70 * 60_000,
            focusedMs: 60 * 60_000,
            fragmentedMs: 0,
            appSwitchCount: 8,
            longestFocusBlockMs: 50 * 60_000,
            dominantApp: "Xcode",
            dominantCategory: .development
        )
        let context = phase13Context(stats: stats, continuitySeconds: 70 * 60)
        let results = NoxSystemContradictionEngine.evaluate(
            system: system,
            context: context,
            preferences: .default
        )
        #expect(results.contains { $0.type == .longSessionWithoutDisplayProtection })
    }

    @Test @MainActor func highInterruptionCostContradictionSuppressedByOrchestratorGates() {
        let utility = phase13UtilitySnapshot(interruptionCost: 0.9, preferSilence: false)
        let context = phase13Context(stats: .empty, continuitySeconds: 50 * 60)
        var persistence = NoxSystemStatePersistence.initial
        let system = NoxSystemStateSnapshot(
            focusReading: .available,
            focusAuthorized: true,
            displaySleepPrevented: false,
            noxCaffeinateActive: false,
            batteryLevel: nil,
            isCharging: false,
            onExternalPower: false,
            lowPowerModeEnabled: false,
            externalDisplayConnected: false,
            appearanceIsDark: true,
            hourOfDay: 10,
            signalsReliable: false
        )
        let contradiction = NoxSystemContradiction(
            id: "x",
            type: .highInterruptionCostWithoutQuietState,
            label: "Quieter system",
            detail: "detail",
            confidence: 0.9,
            explainabilityDetail: NoxSystemContradictionPresenter.explainabilityDetail,
            actions: []
        )
        let eligible = NoxSystemContradictionSuppressionModel.eligible(
            [contradiction],
            system: system,
            preferSilence: false,
            interruptionCost: 0.9,
            receptiveness: utility.receptiveness,
            persistence: persistence
        )
        #expect(eligible == nil)

        let integrated = NoxSystemStateOrchestrator.integrate(
            utility: utility,
            behavioralIntervention: nil,
            context: context,
            preferences: .default,
            persistence: &persistence,
            provider: MockSystemStateProvider(stub: system)
        )
        #expect(integrated.intervention == nil)
    }

    @Test func recoveryWindowContradictionUsesDecompressionSignals() {
        let system = MockSystemStateProvider(stub: .unknown).snapshot(noxCaffeinateActive: false, at: Date())
        let stats = NoxMemoryDayStats(
            periodLabel: "Today",
            totalActiveMs: 50 * 60_000,
            focusedMs: 40 * 60_000,
            fragmentedMs: 0,
            appSwitchCount: 4,
            longestFocusBlockMs: 45 * 60_000,
            dominantApp: nil,
            dominantCategory: .development
        )
        var context = phase13Context(stats: stats, continuitySeconds: 10 * 60, isUserIdle: true)
        context = NoxSystemContradictionContext(
            stats: context.stats,
            focus: context.focus,
            threads: context.threads,
            receptiveness: context.receptiveness,
            decompression: NoxDecompressionState(
                inDecompression: true,
                recoveryWindowOpen: true,
                passiveCollapseLoop: false,
                overloadAfterCoordination: false,
                confidence: 0.7
            ),
            recoveryWindow: NoxRecoveryWindowModel(isOpen: true, label: "", detail: "", confidence: 0.7),
            preferSilence: false,
            interruptionCost: 0.3,
            observationContinuitySeconds: context.observationContinuitySeconds,
            isUserIdle: true,
            dominantCategory: .development,
            returningAfterAbsence: false,
            previousDominantCategory: nil
        )
        let results = NoxSystemContradictionEngine.evaluate(
            system: system,
            context: context,
            preferences: .default
        )
        #expect(results.contains { $0.type == .recoveryWindowAfterLongFocus })
    }

    @Test func batterySensitiveLongSessionRequiresLowBattery() {
        let system = NoxSystemStateSnapshot(
            focusReading: .unknown,
            focusAuthorized: false,
            displaySleepPrevented: false,
            noxCaffeinateActive: false,
            batteryLevel: 0.2,
            isCharging: false,
            onExternalPower: false,
            lowPowerModeEnabled: false,
            externalDisplayConnected: false,
            appearanceIsDark: true,
            hourOfDay: 15,
            signalsReliable: true
        )
        let stats = NoxMemoryDayStats(
            periodLabel: "Today",
            totalActiveMs: 50 * 60_000,
            focusedMs: 40 * 60_000,
            fragmentedMs: 0,
            appSwitchCount: 5,
            longestFocusBlockMs: 30 * 60_000,
            dominantApp: nil,
            dominantCategory: .development
        )
        let context = phase13Context(stats: stats, continuitySeconds: 50 * 60)
        let results = NoxSystemContradictionEngine.evaluate(
            system: system,
            context: context,
            preferences: .default
        )
        #expect(results.contains { $0.type == .batterySensitiveLongSession })
    }

    @Test func systemContradictionCooldownBlocksRepeat() {
        var persistence = NoxSystemStatePersistence.initial
        persistence.lastSystemInterventionAt = Date().addingTimeInterval(-60)
        let contradiction = NoxSystemContradiction(
            id: "a",
            type: .sleepFocusDuringActiveWork,
            label: "Sleep Focus still appears active.",
            detail: "detail",
            confidence: 0.8,
            explainabilityDetail: NoxSystemContradictionPresenter.explainabilityDetail,
            actions: []
        )
        let eligible = NoxSystemContradictionSuppressionModel.eligible(
            [contradiction],
            system: NoxSystemStateSnapshot.unknown,
            preferSilence: false,
            interruptionCost: 0.2,
            receptiveness: phase13UtilitySnapshot(interruptionCost: 0.2, preferSilence: false).receptiveness,
            persistence: persistence
        )
        #expect(eligible == nil)
    }

    @Test func dismissalExtendsPerTypeCooldown() {
        var persistence = NoxSystemStatePersistence.initial
        NoxSystemContradictionSuppressionModel.recordDismissal(
            type: .sleepFocusDuringActiveWork,
            persistence: &persistence,
            at: Date()
        )
        let contradiction = NoxSystemContradiction(
            id: "a",
            type: .sleepFocusDuringActiveWork,
            label: "Sleep Focus still appears active.",
            detail: "detail",
            confidence: 0.8,
            explainabilityDetail: NoxSystemContradictionPresenter.explainabilityDetail,
            actions: []
        )
        let eligible = NoxSystemContradictionSuppressionModel.eligible(
            [contradiction],
            system: NoxSystemStateSnapshot(
                focusReading: .doNotDisturb,
                focusAuthorized: true,
                displaySleepPrevented: false,
                noxCaffeinateActive: false,
                batteryLevel: 0.9,
                isCharging: true,
                onExternalPower: true,
                lowPowerModeEnabled: false,
                externalDisplayConnected: false,
                appearanceIsDark: true,
                hourOfDay: 12,
                signalsReliable: true
            ),
            preferSilence: false,
            interruptionCost: 0.2,
            receptiveness: phase13UtilitySnapshot(interruptionCost: 0.2, preferSilence: false).receptiveness,
            persistence: persistence
        )
        #expect(eligible == nil)
    }

    @Test @MainActor func caffeinateLifecycleStartsAndStopsExplicitly() {
        let controller = NoxCaffeinateController.shared
        controller.stop()
        let session = controller.start(durationSeconds: 60, reason: "test")
        #expect(session != nil)
        #expect(controller.isActive())
        let stopped = controller.stop()
        #expect(stopped?.stoppedAt != nil)
        #expect(!controller.isActive())
    }

    @Test @MainActor func systemActionsNeverRunWithoutExplicitPerform() {
        var persistence = NoxSystemStatePersistence.initial
        let action = NoxSystemActionPermissionModel.candidate(
            kind: .openFocusSettings,
            title: "Open Focus settings",
            detail: "",
            contradictionType: nil
        )
        #expect(persistence.actionHistory.isEmpty)
        _ = NoxSystemActionExecutor.perform(
            action,
            contradictionType: .sleepFocusDuringActiveWork,
            preferences: .default,
            persistence: &persistence,
            observationContinuitySeconds: 0
        )
        #expect(!persistence.actionHistory.isEmpty)
    }

    @Test func systemContradictionExplainabilityCopyIsObservational() {
        let intervention = NoxSystemContradictionPresenter.intervention(
            from: NoxSystemContradiction(
                id: "1",
                type: .contextMismatchAfterReturn,
                label: "System state may not match the current context.",
                detail: "A Focus mode from before the absence may still be active.",
                confidence: 0.7,
                explainabilityDetail: NoxSystemContradictionPresenter.explainabilityDetail,
                actions: []
            )
        )
        #expect(intervention.assuranceLine == "Nothing was changed automatically.")
        #expect(intervention.explainabilityDetail?.contains("local activity") == true)
        let combined = "\(intervention.label) \(intervention.detail)".lowercased()
        #expect(!combined.contains("should take a break"))
        #expect(!combined.contains("overworking"))
    }

    private func phase13Context(
        stats: NoxMemoryDayStats,
        continuitySeconds: TimeInterval,
        isUserIdle: Bool = false
    ) -> NoxSystemContradictionContext {
        NoxSystemContradictionContext(
            stats: stats,
            focus: NoxFocusAnalysis(kind: .deepWork, uninterruptedMs: Int(continuitySeconds * 1000), switchCount: 4, continuityScore: 0.85),
            threads: [],
            receptiveness: NoxInterventionReceptiveness(
                score: 0.7,
                interruptionSensitive: false,
                deepFocusStable: true,
                recoveryOpen: false,
                fragmented: false,
                passiveDecompression: false
            ),
            decompression: NoxDecompressionState(
                inDecompression: false,
                recoveryWindowOpen: false,
                passiveCollapseLoop: false,
                overloadAfterCoordination: false,
                confidence: 0
            ),
            recoveryWindow: NoxRecoveryWindowModel(isOpen: false, label: "", detail: "", confidence: 0),
            preferSilence: false,
            interruptionCost: 0.4,
            observationContinuitySeconds: continuitySeconds,
            isUserIdle: isUserIdle,
            dominantCategory: stats.dominantCategory,
            returningAfterAbsence: false,
            previousDominantCategory: nil
        )
    }

    private func phase13UtilitySnapshot(
        interruptionCost: Double,
        preferSilence: Bool
    ) -> NoxAmbientUtilitySnapshot {
        NoxAmbientUtilitySnapshot(
            nudges: [],
            primaryNudge: nil,
            calmness: NoxAdaptiveCalmnessProfile(
                reflectionDensity: 0.5,
                resurfacingFrequency: 0.5,
                interventionProbability: 0.8,
                notificationProbability: 0.5,
                continuitySurfacingDepth: 0.5,
                preferSilence: preferSilence
            ),
            receptiveness: NoxInterventionReceptiveness(
                score: 0.7,
                interruptionSensitive: interruptionCost >= 0.78,
                deepFocusStable: true,
                recoveryOpen: false,
                fragmented: false,
                passiveDecompression: false
            ),
            decompression: NoxDecompressionState(
                inDecompression: false,
                recoveryWindowOpen: false,
                passiveCollapseLoop: false,
                overloadAfterCoordination: false,
                confidence: 0
            ),
            recoveryWindow: NoxRecoveryWindowModel(isOpen: false, label: "", detail: "", confidence: 0),
            unfinishedThreads: [],
            structuralWeights: [],
            attentionInsight: nil,
            preferSilence: preferSilence,
            notificationCandidate: nil,
            refinedIntervention: nil,
            calibration: NoxAmbientUtilityCalibration(
                trustScore: 0.72,
                notificationFatigue: 0,
                interruptionCost: interruptionCost,
                globalRestraint: 1,
                preferSilence: preferSilence,
                recoveryQuality: NoxRecoveryQualityModel(
                    kind: .neutral,
                    suppressResurfacing: false,
                    preferSilence: false,
                    allowGentleContinuity: true,
                    confidence: 0.5
                ),
                prioritizedThreadIds: [],
                prioritizedArcIds: [],
                experientialPriorities: []
            )
        )
    }
}
