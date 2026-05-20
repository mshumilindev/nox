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

struct NoxLiveContextPresenterTests {

    @Test func suppressesTelemetryInPresentation() {
        let signals = [
            NoxLiveSignal(id: "1", timestamp: Date(), text: "Activity resumed", kind: .idle),
            NoxLiveSignal(
                id: "semantic-1",
                timestamp: Date(),
                text: "Fragmented attention period",
                kind: .awareness
            )
        ]
        let presentation = NoxLiveContextPresenter.present(signals: signals)
        #expect(presentation.pulse.contains { $0.text == "Scattered attention" })
        #expect(!presentation.detail.contains { $0.text == "Activity resumed" })
    }

    @Test func collapsesNearbyPulseDuplicates() {
        let now = Date()
        let signals = [
            NoxLiveSignal(
                id: "continuity-1",
                timestamp: now,
                text: "Fragmented attention period resumed",
                kind: .awareness
            ),
            NoxLiveSignal(
                id: "semantic-1",
                timestamp: now.addingTimeInterval(-20),
                text: "Fragmented attention period",
                kind: .awareness
            ),
            NoxLiveSignal(id: "idle-1", timestamp: now.addingTimeInterval(-30), text: "User idle", kind: .idle),
            NoxLiveSignal(id: "idle-2", timestamp: now.addingTimeInterval(-50), text: "User idle", kind: .idle)
        ]

        let presentation = NoxLiveContextPresenter.present(signals: signals)

        #expect(presentation.pulse.count == 1)
        #expect(presentation.pulse.first?.text == "Scattered attention")
        #expect(!presentation.detail.contains { $0.text.localizedCaseInsensitiveContains("user idle") })
    }

    @Test func collapsesPipelineAndSignalDuplicatePulse() {
        let now = Date()
        let signals = [
            NoxLiveSignal(
                id: "pulse-live-current",
                timestamp: now,
                text: "Focused in Codex",
                kind: .awareness,
                lifecycle: .transient(40)
            )
        ]

        let presentation = NoxLiveContextPresenter.present(
            signals: signals,
            contextLabel: "Focused in Codex"
        )

        #expect(presentation.pulse.map(\.text) == ["Focused in Codex"])
    }

    @Test func currentStreamingContextSuppressesStaleFragmentedPulse() {
        let now = Date()
        let inference = NoxSemanticInference(
            state: .passiveConsumption,
            confidence: 0.85,
            displayPhrase: "Watching",
            reasons: [],
            fusionLabel: .likelyPassiveEntertainment,
            fusionConfidence: 0.8,
            fusionPhrase: "Passive viewing",
            sensitivityLevel: .normal,
            browserCategory: .entertainment,
            aiWorkflow: nil,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )
        let signals = [
            NoxLiveSignal(
                id: "semantic-old",
                timestamp: now.addingTimeInterval(-30),
                text: "Fragmented attention period",
                kind: .awareness
            ),
            NoxLiveSignal(
                id: "semantic-current",
                timestamp: now,
                text: "Watching",
                kind: .awareness
            )
        ]

        let presentation = NoxLiveContextPresenter.present(
            signals: signals,
            semanticContext: inference
        )

        #expect(presentation.pulse.map(\.text) == ["Watching"])
    }

    @Test func contextualPassivePulseCanUseSafeWindowTitle() {
        let inference = NoxSemanticInference(
            state: .passiveConsumption,
            confidence: 0.85,
            displayPhrase: "Watching",
            reasons: [],
            fusionLabel: .likelyPassiveEntertainment,
            fusionConfidence: 0.8,
            fusionPhrase: "Passive viewing",
            sensitivityLevel: .normal,
            browserCategory: .entertainment,
            aiWorkflow: nil,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )

        let presentation = NoxLiveContextPresenter.present(
            signals: [],
            semanticContext: inference,
            contextLabel: "LELEKA - Ridnym (LIVE)"
        )

        #expect(presentation.pulse.first?.text == "Watching LELEKA - Ridnym (LIVE)")
    }

    @Test func privateContextDoesNotUseWindowTitleInPulse() {
        let inference = NoxSemanticInference(
            state: .unknown,
            confidence: 0.9,
            displayPhrase: "Private activity",
            reasons: [],
            fusionLabel: .unknown,
            fusionConfidence: 0.9,
            fusionPhrase: "Private activity",
            sensitivityLevel: .privateContext,
            browserCategory: .privateBrowsing,
            aiWorkflow: nil,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )

        let presentation = NoxLiveContextPresenter.present(
            signals: [],
            semanticContext: inference,
            contextLabel: "Specific private title"
        )

        #expect(presentation.pulse.first?.text == "Private context")
    }

    @Test func currentWritingContextSuppressesStalePassivePulse() {
        let now = Date()
        let inference = NoxSemanticInference(
            state: .writing,
            confidence: 0.75,
            displayPhrase: "Writing",
            reasons: [],
            fusionLabel: .likelyAIAssistedWork,
            fusionConfidence: 0.7,
            fusionPhrase: "AI-assisted work",
            sensitivityLevel: .normal,
            browserCategory: .aiWorkflow,
            aiWorkflow: .promptWriting,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )
        let signals = [
            NoxLiveSignal(
                id: "semantic-old",
                timestamp: now.addingTimeInterval(-20),
                text: "Watching",
                kind: .awareness
            )
        ]

        let presentation = NoxLiveContextPresenter.present(
            signals: signals,
            semanticContext: inference
        )

        #expect(presentation.pulse.map(\.text) == ["Writing"])
    }

    @Test func separatesPulseAndAppTrailDetail() {
        let now = Date()
        let inference = NoxSemanticInference(
            state: .fragmentedInteraction,
            confidence: 0.75,
            displayPhrase: "",
            reasons: [],
            fusionLabel: .likelyAIAssistedWork,
            fusionConfidence: 0.7,
            fusionPhrase: "",
            sensitivityLevel: .normal,
            browserCategory: .aiWorkflow,
            aiWorkflow: .researchHeavy,
            aiWorkflowPhrase: nil,
            shouldSurface: true
        )
        let signals = [
            NoxLiveSignal(
                id: "semantic-1",
                timestamp: now,
                text: "Fragmented attention period",
                kind: .awareness
            ),
            NoxLiveSignal(id: "1", timestamp: now, text: "Switched to ChatGPT", kind: .app),
            NoxLiveSignal(id: "2", timestamp: now.addingTimeInterval(-40), text: "Switched to Cursor", kind: .app)
        ]
        let presentation = NoxLiveContextPresenter.present(
            signals: signals,
            semanticContext: inference
        )
        #expect(!presentation.pulse.isEmpty)
        if let trail = presentation.detail.first?.text {
            #expect(trail.contains("→"))
        }
    }
}
