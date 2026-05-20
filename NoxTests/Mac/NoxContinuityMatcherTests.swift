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

struct NoxContinuityMatcherTests {

    @Test func matchesSimilarAIDevEcosystem() {
        let signature = NoxContinuitySignature(
            ecosystemKey: "ai-dev",
            semanticType: .aiDevelopment,
            appTokens: ["chatgpt", "cursor"],
            semanticState: .writing,
            fusionLabel: .likelyAIAssistedWork,
            interactionProfile: "writing-heavy",
            densityProfile: "moderate"
        )
        let thread = NoxContinuityThread(
            id: "t1",
            semanticType: .aiDevelopment,
            title: "AI-assisted development continuity",
            dominantApps: ["Cursor", "Terminal"],
            dominantCategories: [],
            dominantDomains: [],
            continuitySignature: NoxContinuitySignature(
                ecosystemKey: "ai-dev",
                semanticType: .aiDevelopment,
                appTokens: ["cursor", "terminal", "github"],
                semanticState: .writing,
                fusionLabel: .likelyAIAssistedWork,
                interactionProfile: "writing-heavy",
                densityProfile: "dense"
            ),
            firstSeenAt: Date().addingTimeInterval(-4 * 3600),
            lastSeenAt: Date().addingTimeInterval(-2 * 3600),
            totalActiveDurationMs: 1_800_000,
            totalSessions: 2,
            totalResumptions: 1,
            continuityStrength: 0.75,
            recurrenceStrength: 0.4,
            interruptionPattern: "steady",
            currentStatus: .paused,
            recentMemoryIds: [],
            linkedSpanIds: ["s1"],
            linkedSessionIds: [],
            supportingSignals: [],
            confidence: 0.72,
            lastResumedAt: Date().addingTimeInterval(-2 * 3600),
            temporalPatterns: ["afternoon"],
            decayState: .fading,
            sensitivityLevel: .normal
        )
        let result = NoxContinuityMatcher.score(
            signature: signature,
            against: thread,
            at: Date(),
            gap: 2 * 3600
        )
        #expect(result.totalScore >= NoxContinuityConfidence.attachThreshold)
    }

    @Test func generalContinuityKeepsDistinctAppIdentity() {
        let inference = NoxSemanticInference(
            state: .activeInteraction,
            confidence: 0.7,
            displayPhrase: "",
            reasons: [],
            fusionLabel: .unknown,
            fusionConfidence: 0.2,
            fusionPhrase: "",
            sensitivityLevel: .normal,
            browserCategory: .unknown,
            aiWorkflow: nil,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )

        let figma = NoxContinuitySignature.from(
            inference: inference,
            appNames: ["Figma"],
            appName: "Figma"
        )
        let notes = NoxContinuitySignature.from(
            inference: inference,
            appNames: ["Notes"],
            appName: "Notes"
        )

        #expect(figma.semanticType == .general)
        #expect(notes.semanticType == .general)
        #expect(figma.ecosystemKey != notes.ecosystemKey)
    }

    @Test func resurfacingCopyIsHumble() {
        let thread = NoxContinuityThread(
            id: "t1",
            semanticType: .research,
            title: "Research continuity",
            dominantApps: ["Safari"],
            dominantCategories: [],
            dominantDomains: [],
            continuitySignature: NoxContinuitySignature(
                ecosystemKey: "research",
                semanticType: .research,
                appTokens: ["safari"],
                semanticState: .reading,
                fusionLabel: .likelyResearch,
                interactionProfile: "reading-heavy",
                densityProfile: "moderate"
            ),
            firstSeenAt: Date().addingTimeInterval(-86_400),
            lastSeenAt: Date().addingTimeInterval(-3 * 3600),
            totalActiveDurationMs: 2_400_000,
            totalSessions: 4,
            totalResumptions: 2,
            continuityStrength: 0.8,
            recurrenceStrength: 0.55,
            interruptionPattern: "steady",
            currentStatus: .resumed,
            recentMemoryIds: [],
            linkedSpanIds: [],
            linkedSessionIds: [],
            supportingSignals: [],
            confidence: 0.78,
            lastResumedAt: Date(),
            temporalPatterns: ["evening"],
            decayState: .active,
            sensitivityLevel: .normal
        )
        let match = NoxContinuityMatchResult(
            threadId: thread.id,
            totalScore: 0.8,
            components: [],
            isResumption: true
        )
        let resurfacing = NoxContinuityResurfacingPresenter.resurfacing(
            for: thread,
            match: match,
            at: Date()
        )
        #expect(resurfacing?.primaryText == "Research resumed")
        #expect(resurfacing?.primaryText.localizedCaseInsensitiveContains("should") == false)
        #expect(resurfacing?.primaryText.localizedCaseInsensitiveContains("unfinished") == false)
    }

    @Test func personalContinuityIsGeneralizedInPresentation() {
        let thread = NoxContinuityThread(
            id: "private",
            semanticType: .general,
            title: "Personal browsing continuity",
            dominantApps: ["Safari"],
            dominantCategories: [],
            dominantDomains: [],
            continuitySignature: NoxContinuitySignature(
                ecosystemKey: "general-safari",
                semanticType: .general,
                appTokens: ["safari"],
                semanticState: .unknown,
                fusionLabel: .unknown,
                interactionProfile: "mixed",
                densityProfile: "moderate"
            ),
            firstSeenAt: Date().addingTimeInterval(-3600),
            lastSeenAt: Date().addingTimeInterval(-1800),
            totalActiveDurationMs: 600_000,
            totalSessions: 2,
            totalResumptions: 1,
            continuityStrength: 0.8,
            recurrenceStrength: 0.5,
            interruptionPattern: "steady",
            currentStatus: .resumed,
            recentMemoryIds: [],
            linkedSpanIds: [],
            linkedSessionIds: [],
            supportingSignals: [],
            confidence: 0.8,
            lastResumedAt: Date(),
            temporalPatterns: ["evening"],
            decayState: .active,
            sensitivityLevel: .personal
        )

        #expect(NoxContinuityResurfacingPresenter.threadDisplayTitle(thread) == "Private continuity")
        #expect(NoxContinuityResurfacingPresenter.threadDetailLine(thread) == "Generalized activity only")
    }
}
