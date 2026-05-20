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

struct NoxAmbientUtilityCalibrationPhase11_5Tests {

    @Test func notificationCalibrationBlocksHighFatigue() {
        let allows = NoxNotificationCalibrationEngine.calibratedAllows(
            candidate: NoxAmbientNotificationCandidate(
                id: "n1",
                kind: "unfinished_continuity",
                title: "Nox",
                body: "A thread resurfaced.",
                confidence: 0.6
            ),
            fatigue: 0.8,
            trustScore: 0.5,
            interruptionCost: 0.4,
            baseAllows: true,
            preferSilence: false
        )
        #expect(!allows)
    }

    @Test func silenceRefinementDuringPassiveCollapse() {
        let quality = NoxRecoveryQualityModel(
            kind: .passiveCollapse,
            suppressResurfacing: true,
            preferSilence: true,
            allowGentleContinuity: false,
            confidence: 0.65
        )
        #expect(NoxSilenceRefinementEngine.preferSilence(
            basePreferSilence: false,
            recoveryQuality: quality,
            interruptionCost: 0.5,
            receptiveness: NoxInterventionReceptiveness(
                score: 0.5,
                interruptionSensitive: false,
                deepFocusStable: false,
                recoveryOpen: false,
                fragmented: false,
                passiveDecompression: true
            ),
            calmness: .balanced,
            globalRestraint: 0.6
        ))
    }

    @Test func gravityEvolutionWeakensFadingThreads() {
        let thread = NoxContinuityThread(
            id: "t1",
            semanticType: .aiDevelopment,
            title: "Alpha continuity",
            dominantApps: [],
            dominantCategories: [],
            dominantDomains: [],
            continuitySignature: NoxContinuitySignature(
                ecosystemKey: "a",
                semanticType: .aiDevelopment,
                appTokens: [],
                semanticState: .writing,
                fusionLabel: .likelyAIAssistedWork,
                interactionProfile: "steady",
                densityProfile: "moderate"
            ),
            firstSeenAt: Date().addingTimeInterval(-20 * 86_400),
            lastSeenAt: Date(),
            totalActiveDurationMs: 1_000_000,
            totalSessions: 2,
            totalResumptions: 1,
            continuityStrength: 0.35,
            recurrenceStrength: 0.3,
            interruptionPattern: "steady",
            currentStatus: .paused,
            recentMemoryIds: [],
            linkedSpanIds: [],
            linkedSessionIds: [],
            supportingSignals: [],
            confidence: 0.5,
            lastResumedAt: nil,
            temporalPatterns: [],
            decayState: .fading,
            sensitivityLevel: .normal
        )
        let evolved = NoxContinuityGravityEvolutionEngine.evolve(
            threads: [thread],
            arcs: [],
            stored: ["t1": 0.7]
        )
        #expect((evolved["t1"] ?? 1) < 0.7)
    }

    @Test func trustTrackerIncreasesFatigueOnPoorTiming() {
        var trust = NoxAmbientTrustState.initial
        NoxNotificationTrustTracker.recordRefresh(
            trust: &trust,
            notificationDelivered: true,
            notificationSuppressed: false,
            preferSilence: false,
            interruptionCost: 0.8,
            poorTiming: true
        )
        #expect(trust.notificationFatigue > 0.1)
        #expect(trust.poorTimingEventCount >= 1)
    }
}
