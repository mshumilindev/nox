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

struct NoxReflectiveContinuityTests {

    @Test func morningEngineProducesCalmCopy() {
        let stats = NoxMemoryDayStats(
            periodLabel: "Today",
            totalActiveMs: 600_000,
            focusedMs: 200_000,
            fragmentedMs: 100_000,
            appSwitchCount: 4,
            longestFocusBlockMs: 0,
            dominantApp: "Xcode",
            dominantCategory: nil
        )
        let snapshot = NoxMorningContinuityEngine.buildSnapshot(
            trigger: .morningWindow,
            at: Date(),
            threads: [],
            semanticSpans: [],
            stats: stats,
            focus: nil,
            continuityNote: nil,
            lastShutdownAt: Date().addingTimeInterval(-12 * 3600)
        )
        let summary = NoxMorningSummaryPresenter.present(snapshot: snapshot)
        #expect(summary != nil)
        #expect(summary?.headline.localizedCaseInsensitiveContains("productive") == false)
        #expect(summary?.headline.localizedCaseInsensitiveContains("goal") == false)
    }

    @Test func emergingMemoryNeverUsesContextsAreForming() {
        let span = NoxSemanticMemorySpan(
            id: "s1",
            startedAt: Date().addingTimeInterval(-120),
            endedAt: nil,
            title: "Development context",
            subtitle: "Xcode",
            interactionStyle: "Focused",
            semanticState: .sustainedInteraction,
            fusionLabel: .likelyWorkRelated,
            sensitivityLevel: .normal,
            confidence: 0.5,
            appNames: ["Xcode"],
            reasonsJson: nil
        )
        let result = NoxEmergingMemoryEngine.observe(
            semanticSpans: [],
            openSpan: span,
            threads: [],
            stats: NoxMemoryDayStats(
                periodLabel: "Today",
                totalActiveMs: 120_000,
                focusedMs: 0,
                fragmentedMs: 0,
                appSwitchCount: 2,
                longestFocusBlockMs: 0,
                dominantApp: nil,
                dominantCategory: nil
            ),
            liveSignalCount: 2,
            continuitySeconds: 400
        )
        let copy = NoxEmergingMemoryEngine.primaryCopy(
            maturity: result.maturity,
            observations: result.observations,
            readiness: .building
        )
        #expect(copy.title != "Contexts are forming")
        #expect(!result.observations.isEmpty || result.maturity != .transient)
    }

    @Test func reflectiveSynthesisRespectsCooldown() {
        let recent = Date().addingTimeInterval(-60)
        #expect(NoxReflectiveSynthesisEngine.shouldSynthesize(lastReflectionAt: recent) == false)
        #expect(NoxReflectiveSynthesisEngine.shouldSynthesize(lastReflectionAt: nil) == true)
    }

    @Test func reflectionPresenterDedupesIdenticalText() {
        let now = Date()
        let duplicate = NoxReflectionCandidate(
            id: "a",
            text: "Same observation.",
            detailLine: "Detail A",
            confidence: 0.6,
            createdAt: now,
            sourceSignals: []
        )
        let other = NoxReflectionCandidate(
            id: "b",
            text: "Same observation.",
            detailLine: "Detail B",
            confidence: 0.55,
            createdAt: now.addingTimeInterval(-60),
            sourceSignals: []
        )
        let unique = NoxReflectionCandidate(
            id: "c",
            text: "Different observation.",
            detailLine: "Detail C",
            confidence: 0.54,
            createdAt: now.addingTimeInterval(-120),
            sourceSignals: []
        )
        let distinct = NoxReflectionPresenter.distinct([duplicate, other, unique], limit: 4)
        #expect(distinct.count == 2)
        #expect(distinct.map(\.text).contains("Different observation."))
    }

    @Test func reflectiveSynthesisProducesDistinctStableIds() {
        let input = NoxReflectionInput(
            periodLabel: "Today",
            semanticThemes: ["Development", "Research"],
            continuityResumptions: 3,
            fragmentedSessions: 2,
            dominantArcLabels: ["Creative exploration"],
            resurfacedArcLabels: ["AI-assisted development"],
            recurringThreadTitles: ["AI-assisted development continuity"],
            observationHours: 6,
            hasPriorDayActivity: true,
            behavioralPatternLabels: ["Deep-focus streak"],
            behavioralPatternDetails: ["Sustained focus blocks have been forming locally."],
            temporalRhythmLabels: ["Weekly rhythm"],
            temporalRhythmDetails: ["Work density clusters mid-week."],
            driftObservation: "Less stable rhythms. Recent rhythms have been less stable than usual.",
            lifeStructureLabels: ["Coordination-heavy era"],
            lifeStructureDetails: ["Scheduling and communication may be shaping the week."],
            focusSummary: "fragmented attention",
            weeklyHorizonSnippet: "Development and research alternated across the week with calmer evenings."
        )
        let results = NoxReflectiveSynthesisEngine.synthesize(input: input)
        #expect(results.count >= 2)
        #expect(Set(results.map(\.id)).count == results.count)
        #expect(results.allSatisfy { !$0.detailLine.isEmpty })
        #expect(Set(results.map(\.text)).count == results.count)
    }

    @Test func semanticArcsGroupDevelopmentSpans() {
        let base = Date().addingTimeInterval(-3600)
        let spans = (0..<3).map { index in
            NoxSemanticMemorySpan(
                id: "dev-\(index)",
                startedAt: base.addingTimeInterval(Double(index) * 900),
                endedAt: base.addingTimeInterval(Double(index) * 900 + 600),
                title: "Development context",
                subtitle: "Apps",
                interactionStyle: "",
                semanticState: .sustainedInteraction,
                fusionLabel: .likelyWorkRelated,
                sensitivityLevel: .normal,
                confidence: 0.6,
                appNames: ["Xcode"],
                reasonsJson: nil
            )
        }
        let arcs = NoxSemanticArcEngine.buildArcs(spans: spans, threads: [])
        #expect(!arcs.isEmpty)
        #expect(arcs.contains { $0.arcType == .development })
    }

    @Test func resurfacingOrchestratorLimitsFrequency() {
        let notes = NoxContinuityResurfacingOrchestrator.resurfacingNotes(
            threads: [],
            arcs: [],
            lastShownAt: Date(),
            at: Date()
        )
        #expect(notes.isEmpty)
    }
}
