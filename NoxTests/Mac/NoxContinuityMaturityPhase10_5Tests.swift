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

struct NoxContinuityMaturityPhase10_5Tests {

    @Test func languageSoftenerRemovesEngineVocabulary() {
        let raw = "Fragmented context period alongside oscillating cadence detected."
        let softened = NoxReflectiveLanguageSoftener.soften(raw)
        #expect(!softened.localizedCaseInsensitiveContains("oscillating cadence"))
        #expect(!softened.localizedCaseInsensitiveContains("detected"))
    }

    @Test func reflectionSuppressionLimitsMarginalReflections() {
        let context = NoxContinuityMaturityContext.build(
            input: .empty,
            focus: nil,
            behavioral: .empty,
            connectorSnapshot: .empty
        )
        let matured = NoxMaturedReflection(
            candidate: NoxReflectionCandidate(
                id: "reflection-focus-rhythm",
                text: "Today leaned toward fragmented attention.",
                detailLine: "From focus blocks.",
                confidence: 0.53,
                createdAt: Date(),
                sourceSignals: []
            ),
            gravity: 0.4,
            salience: .quiet
        )
        #expect(NoxReflectionSuppressionEngine.shouldSuppress(
            matured: matured,
            stored: [],
            context: context
        ))
    }

    @Test func naturalizationGroundsTemporalPhrasing() {
        let candidate = NoxReflectionCandidate(
            id: "reflection-fragmentation",
            text: "Attention split across contexts.",
            detailLine: "From focus analysis.",
            confidence: 0.58,
            createdAt: Date(),
            sourceSignals: []
        )
        let input = NoxReflectionInput(
            periodLabel: "Today",
            semanticThemes: [],
            continuityResumptions: 0,
            fragmentedSessions: 3,
            dominantArcLabels: [],
            resurfacedArcLabels: [],
            recurringThreadTitles: [],
            observationHours: 4,
            hasPriorDayActivity: false,
            behavioralPatternLabels: [],
            behavioralPatternDetails: [],
            temporalRhythmLabels: [],
            temporalRhythmDetails: [],
            driftObservation: nil,
            lifeStructureLabels: [],
            lifeStructureDetails: [],
            focusSummary: "fragmented attention",
            weeklyHorizonSnippet: nil
        )
        let naturalized = NoxReflectionNaturalizationEngine.naturalize(
            candidate,
            input: input,
            salience: .fragile
        )
        #expect(naturalized.text.lowercased().contains("recent"))
    }

    @Test func maturityOrchestratorReturnsAtMostThreeReflections() {
        let input = NoxReflectionInput(
            periodLabel: "Today",
            semanticThemes: ["Development", "Research"],
            continuityResumptions: 4,
            fragmentedSessions: 3,
            dominantArcLabels: ["AI-assisted development"],
            resurfacedArcLabels: ["AI-assisted development"],
            recurringThreadTitles: ["AI-assisted development continuity"],
            observationHours: 8,
            hasPriorDayActivity: true,
            behavioralPatternLabels: ["Deep-focus streak"],
            behavioralPatternDetails: ["Sustained focus blocks have been forming locally."],
            temporalRhythmLabels: ["Weekly rhythm"],
            temporalRhythmDetails: ["Work density clusters mid-week."],
            driftObservation: "Less stable rhythms. Recent rhythms have been less stable than usual.",
            lifeStructureLabels: ["Coordination-heavy era"],
            lifeStructureDetails: ["Scheduling density may be shaping the week."],
            focusSummary: "fragmented attention",
            weeklyHorizonSnippet: "Development and research alternated with quieter evenings across the week."
        )
        let raw = NoxReflectiveSynthesisEngine.synthesize(input: input)
        let matured = NoxContinuityMaturityOrchestrator.matureReflections(
            raw,
            input: input,
            stored: [],
            threads: [],
            arcs: [],
            behavioral: .empty,
            focus: nil,
            connectorSnapshot: .empty
        )
        #expect(matured.count <= 3)
        #expect(matured.allSatisfy { !$0.text.localizedCaseInsensitiveContains("oscillating cadence") })
    }
}
