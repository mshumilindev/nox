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

struct NoxAmbientUtilityPhase11Tests {

    @Test func calmnessReducesReflectionDuringFragmentation() {
        let calmness = NoxAdaptiveCalmnessEngine.profile(
            receptiveness: NoxInterventionReceptiveness(
                score: 0.35,
                interruptionSensitive: true,
                deepFocusStable: false,
                recoveryOpen: false,
                fragmented: true,
                passiveDecompression: false
            ),
            decompression: NoxDecompressionState(
                inDecompression: false,
                recoveryWindowOpen: false,
                passiveCollapseLoop: false,
                overloadAfterCoordination: false,
                confidence: 0.4
            ),
            behavioral: .empty,
            connectorSnapshot: .empty
        )
        #expect(calmness.reflectionDensity < 0.7)
        #expect(calmness.notificationProbability < 0.4)
    }

    @Test func silencePreferredDuringDecompression() {
        let decompression = NoxDecompressionState(
            inDecompression: true,
            recoveryWindowOpen: false,
            passiveCollapseLoop: true,
            overloadAfterCoordination: false,
            confidence: 0.65
        )
        let receptiveness = NoxInterventionReceptivenessModel.evaluate(
            focus: nil,
            stats: .empty,
            behavioral: .empty,
            decompression: decompression
        )
        let calmness = NoxAdaptiveCalmnessEngine.profile(
            receptiveness: receptiveness,
            decompression: decompression,
            behavioral: .empty,
            connectorSnapshot: .empty
        )
        #expect(NoxAmbientSilenceEngine.shouldPreferSilence(
            receptiveness: receptiveness,
            decompression: decompression,
            calmness: calmness,
            behavioral: .empty
        ))
    }

    @Test func notificationCopyAvoidsCoachingLanguage() {
        let candidate = NoxNotificationRelevanceModel.candidate(
            unfinished: [
                NoxUnfinishedContinuityCandidate(
                    id: "u1",
                    label: "Development",
                    detail: "Keeps returning.",
                    persistenceScore: 0.7,
                    resumptions: 3
                )
            ],
            behavioral: .empty,
            receptiveness: NoxInterventionReceptiveness(
                score: 0.6,
                interruptionSensitive: false,
                deepFocusStable: false,
                recoveryOpen: true,
                fragmented: false,
                passiveDecompression: false
            ),
            calmness: .balanced,
            preferSilence: false,
            fragmentedReductionActive: false
        )
        if let candidate {
            let combined = "\(candidate.title) \(candidate.body)".lowercased()
            #expect(!combined.contains("take a break"))
            #expect(!combined.contains("don't forget"))
            #expect(!combined.contains("stay focused"))
        }
    }

    @Test @MainActor func utilityOrchestratorHonorsPause() async {
        let snapshot = NoxAmbientUtilityOrchestrator.refresh(
            paused: true,
            preferences: .default,
            stats: .empty,
            focus: nil,
            threads: [],
            arcs: [],
            connectorSnapshot: .empty,
            behavioralSnapshot: .empty,
            proposedIntervention: nil,
            lastNudgeAt: nil,
            ambientState: .empty
        )
        #expect(snapshot == .empty)
    }
}
