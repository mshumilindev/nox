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

struct NoxMemoryEvolutionPhase12Tests {

    @Test func memoryAgingMarksDormantThreads() {
        let thread = NoxContinuityThread(
            id: "t-dormant",
            semanticType: .aiDevelopment,
            title: "Beta continuity",
            dominantApps: [],
            dominantCategories: [],
            dominantDomains: [],
            continuitySignature: NoxContinuitySignature(
                ecosystemKey: "b",
                semanticType: .aiDevelopment,
                appTokens: [],
                semanticState: .writing,
                fusionLabel: .likelyAIAssistedWork,
                interactionProfile: "steady",
                densityProfile: "moderate"
            ),
            firstSeenAt: Date().addingTimeInterval(-60 * 86_400),
            lastSeenAt: Date().addingTimeInterval(-20 * 86_400),
            totalActiveDurationMs: 500_000,
            totalSessions: 3,
            totalResumptions: 1,
            continuityStrength: 0.4,
            recurrenceStrength: 0.35,
            interruptionPattern: "steady",
            currentStatus: .paused,
            recentMemoryIds: [],
            linkedSpanIds: [],
            linkedSessionIds: [],
            supportingSignals: [],
            confidence: 0.55,
            lastResumedAt: nil,
            temporalPatterns: [],
            decayState: .dormant,
            sensitivityLevel: .normal
        )
        let profiles = NoxMemoryAgingEngine.profiles(threads: [thread], arcs: [])
        let profile = profiles.first { $0.subjectId == "t-dormant" }
        #expect(profile?.band == .dormant)
        #expect((profile?.resurfacingMultiplier ?? 1) < 0.5)
    }

    @Test func temporalWeightEvolutionIncreasesRecurrentThreads() {
        var stored: [String: Double] = ["t1": 0.4]
        let thread = NoxContinuityThread(
            id: "t1",
            semanticType: .aiDevelopment,
            title: "Gamma continuity",
            dominantApps: [],
            dominantCategories: [],
            dominantDomains: [],
            continuitySignature: NoxContinuitySignature(
                ecosystemKey: "g",
                semanticType: .aiDevelopment,
                appTokens: [],
                semanticState: .writing,
                fusionLabel: .likelyAIAssistedWork,
                interactionProfile: "steady",
                densityProfile: "moderate"
            ),
            firstSeenAt: Date().addingTimeInterval(-90 * 86_400),
            lastSeenAt: Date(),
            totalActiveDurationMs: 2_000_000,
            totalSessions: 8,
            totalResumptions: 3,
            continuityStrength: 0.65,
            recurrenceStrength: 0.7,
            interruptionPattern: "steady",
            currentStatus: .resumed,
            recentMemoryIds: [],
            linkedSpanIds: [],
            linkedSessionIds: [],
            supportingSignals: [],
            confidence: 0.7,
            lastResumedAt: Date(),
            temporalPatterns: [],
            decayState: .active,
            sensitivityLevel: .normal
        )
        let weights = NoxTemporalWeightEvolutionEngine.evolve(
            threads: [thread],
            arcs: [],
            agingProfiles: NoxMemoryAgingEngine.profiles(threads: [thread], arcs: []),
            gravity: [:],
            resilience: ["t1": 0.6],
            stored: &stored
        )
        #expect((weights["t1"] ?? 0) > 0.4)
    }

    @Test func longTermResurfacingRespectsCooldown() {
        let notes = NoxLongTermResurfacingEngine.notes(
            threads: [],
            arcs: [],
            agingProfiles: [],
            unresolved: [],
            lastShownAt: Date().addingTimeInterval(-3600),
            preferSilence: false
        )
        #expect(notes.isEmpty)
    }

    @Test func evolutionOrchestratorHonorsPause() {
        var state = NoxMemoryEvolutionState.initial
        let snapshot = NoxMemoryEvolutionOrchestrator.evolve(
            threads: [],
            arcs: [],
            typedMemories: [],
            gravity: [:],
            behavioral: .empty,
            calibration: .neutral,
            focus: nil,
            stored: &state,
            calmnessAllowsResurfacing: true
        )
        #expect(snapshot.prioritizedThreadIds.isEmpty)
    }
}
