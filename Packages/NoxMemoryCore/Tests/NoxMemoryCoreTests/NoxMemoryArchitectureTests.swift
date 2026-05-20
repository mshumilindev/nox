import Foundation
import NoxMemoryCore
import NoxSemanticCore
import Testing

struct NoxMemoryRetentionPolicyTests {

    @Test func warmTimelineDefaultsToTwoWeeks() {
        let policy = NoxMemoryRetentionPolicy.default
        #expect(policy.warmTimelineDays == 14)
    }

    @Test func hourlyRollupHasShortRetention() {
        let policy = NoxMemoryRetentionPolicy.default
        #expect(policy.hourlyRollupRetentionDays == 7)
    }

    @Test func eraAndYearlyAreIndefinite() {
        let policy = NoxMemoryRetentionPolicy.default
        #expect(policy.retentionDays(for: .era) == nil)
        #expect(policy.retentionDays(for: .yearly) == nil)
    }
}

struct NoxMemoryHorizonTests {

    @Test func eachHorizonHasDistinctSemanticIntent() {
        let intents = Set(NoxMemoryCompressionLevel.allCases.map(\.semanticIntent))
        #expect(intents.count == NoxMemoryCompressionLevel.allCases.count)
        #expect(NoxMemoryCompressionLevel.daily.semanticIntent.contains("happened"))
        #expect(NoxMemoryCompressionLevel.weekly.semanticIntent.contains("repeated"))
        #expect(NoxMemoryCompressionLevel.era.semanticIntent.contains("period"))
    }

    @Test func decadeDecodesAsEra() throws {
        let data = Data("\"decade\"".utf8)
        let level = try JSONDecoder().decode(NoxMemoryCompressionLevel.self, from: data)
        #expect(level == .era)
    }

    @Test func hierarchyIncludesHourlyAndQuarterly() {
        #expect(NoxMemoryCompressionLevel.hourly.childLevel == nil)
        #expect(NoxMemoryCompressionLevel.daily.childLevel == .hourly)
        #expect(NoxMemoryCompressionLevel.quarterly.childLevel == .monthly)
        #expect(NoxMemoryCompressionLevel.era.childLevel == .yearly)
    }
}

struct NoxForbiddenMemoryContentTests {

    @Test func highFrequencyInteractionEventsAreForbiddenFromWarmLayer() {
        #expect(NoxForbiddenMemoryContent.mustNotPersistToWarmTimeline(eventType: .typingBurst))
        #expect(NoxForbiddenMemoryContent.mustNotPersistToWarmTimeline(eventType: .scrollActivity))
    }
}

struct NoxLayerNarrativeTests {

    @Test func dailyAndWeeklyNarrativesDiffer() {
        var facts = NoxRollupFacts(
            totalActiveMs: 3_600_000,
            dominantApps: [NoxRollupAppShare(name: "Cursor", bundleId: "c", durationMs: 2_000_000)]
        )
        facts.repeatedWorkflows = [
            NoxRepeatedPattern(label: "AI workflow", occurrenceCount: 4, totalDurationMs: 1_000_000)
        ]
        let daily = NoxLayerNarrativeBuilder.build(facts: facts, level: .daily)
        let weekly = NoxLayerNarrativeBuilder.build(facts: facts, level: .weekly)
        #expect(daily != weekly)
        #expect(weekly.contains("Recurring"))
    }
}

struct NoxDeterministicRollupEngineTests {

    @Test func weeklyEnrichmentDetectsRepeatedWorkflows() {
        var child = NoxRollupFacts(totalActiveMs: 1_000_000)
        child.topSemanticTitles = ["AI-assisted work"]
        child.dominantApps = [NoxRollupAppShare(name: "Cursor", bundleId: "c", durationMs: 800_000)]
        let merged = NoxDeterministicRollupEngine.aggregateFacts(level: .weekly, from: [child, child, child])
        #expect(!merged.repeatedWorkflows.isEmpty)
    }

    @Test func eraFactsDeriveAdaptiveLabel() {
        var facts = NoxRollupFacts()
        facts.dominantApps = [NoxRollupAppShare(name: "Xcode", bundleId: "x", durationMs: 5_000_000)]
        facts.topSemanticTitles = ["AI-assisted development"]
        let derived = NoxEraDetector.deriveEraFacts(from: [facts])
        #expect(derived.eraLabel != nil)
        #expect(!(derived.eraThemes.isEmpty))
    }
}

struct NoxTypedMemoryExtractorTests {

    @Test func extractsAIWorkflowFromDailyRollup() {
        var facts = NoxRollupFacts(totalActiveMs: 4_000_000)
        facts.topSemanticTitles = ["AI-assisted work"]
        facts.dominantApps = [
            NoxRollupAppShare(name: "Cursor", bundleId: "c", durationMs: 3_000_000),
            NoxRollupAppShare(name: "ChatGPT", bundleId: "g", durationMs: 500_000)
        ]
        let snapshot = NoxDeterministicRollupEngine.makeSnapshot(
            level: .daily,
            periodStart: Date(),
            periodEnd: Date(),
            facts: facts
        )
        let entities = NoxTypedMemoryExtractor.extract(from: snapshot)
        #expect(entities.contains { $0.kind == NoxTypedMemoryKind.aiWorkflow })
        #expect(entities.allSatisfy { !$0.supportingSignals.isEmpty })
    }
}

struct NoxSensitiveMemoryPolicyTests {

    @Test func sensitiveTitlesAreGeneralized() {
        let result = NoxSensitiveMemoryPolicy.sanitizedForLongTermStorage(
            title: "Chase Bank Login",
            subtitle: "account overview",
            sensitivity: .sensitive
        )
        #expect(result.title == "Sensitive context")
        #expect(!result.subtitle.lowercased().contains("bank"))
    }
}

struct NoxExplainableInferencePackageTests {

    @Test func inferencePreservesReasoningChain() {
        let inference = NoxSemanticInference(
            state: .reading,
            confidence: 0.8,
            displayPhrase: "Reading-heavy",
            reasons: [NoxSemanticReason(signal: "scroll", detail: "high scroll density")],
            fusionLabel: .likelyResearch,
            fusionConfidence: 0.7,
            fusionPhrase: "Research context",
            sensitivityLevel: .normal,
            browserCategory: .research,
            aiWorkflow: nil,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )
        let explainable = NoxExplainableInference.from(inference: inference)
        #expect(explainable.isExplainable)
        #expect(explainable.reasoningChain.contains { $0.contains("scroll") })
    }
}
