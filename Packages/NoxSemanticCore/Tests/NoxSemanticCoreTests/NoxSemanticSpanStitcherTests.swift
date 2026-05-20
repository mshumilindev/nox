import Foundation
import NoxSemanticCore
import Testing

struct NoxSemanticSpanStitcherPackageTests {

    @Test func mergesNearbySpansWithSameWorkflowKey() {
        let t0 = Date()
        let a = span(id: "a", title: "AI research session", startedAt: t0, endedAt: t0.addingTimeInterval(600))
        let b = span(
            id: "b",
            title: "AI research session",
            startedAt: t0.addingTimeInterval(900),
            endedAt: t0.addingTimeInterval(1800)
        )
        let stitched = NoxSemanticSpanStitcher.stitch([a, b])
        #expect(stitched.count == 1)
        #expect(stitched[0].durationMs >= 1_200_000)
    }

    @Test func labelCatalogUsesHumanMemoryTitles() {
        let inference = NoxSemanticInference(
            state: .fragmentedInteraction,
            confidence: 0.7,
            displayPhrase: "Fragmented interaction pattern",
            reasons: [],
            fusionLabel: .unknown,
            fusionConfidence: 0,
            fusionPhrase: "",
            sensitivityLevel: .normal,
            browserCategory: .unknown,
            aiWorkflow: nil,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )
        let title = NoxSemanticLabelCatalog.memoryTitle(inference: inference, appName: nil)
        #expect(title == "Scattered attention")
        #expect(!title.localizedCaseInsensitiveContains("likely"))
    }

    private func span(
        id: String,
        title: String,
        startedAt: Date,
        endedAt: Date
    ) -> NoxSemanticMemorySpan {
        NoxSemanticMemorySpan(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            title: title,
            subtitle: "ChatGPT · Cursor",
            interactionStyle: "reading-heavy",
            semanticState: .reading,
            fusionLabel: .likelyAIAssistedWork,
            sensitivityLevel: .normal,
            confidence: 0.7,
            appNames: ["ChatGPT", "Cursor"],
            reasonsJson: nil
        )
    }
}
