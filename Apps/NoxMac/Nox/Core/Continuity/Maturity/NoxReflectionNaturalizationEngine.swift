import Foundation
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
import NoxShrineCore

nonisolated enum NoxReflectionNaturalizationEngine {

    static func naturalize(
        _ candidate: NoxReflectionCandidate,
        input: NoxReflectionInput,
        salience: NoxContinuitySalience
    ) -> NoxReflectionCandidate {
        let headline = naturalHeadline(candidate: candidate, input: input, salience: salience)
        let detail = NoxTemporalGroundingEngine.groundedDetail(
            reflectionId: candidate.id,
            rawDetail: candidate.detailLine
        )
        return NoxReflectionCandidate(
            id: candidate.id,
            text: NoxEmotionalSafetyCopy.sanitize(headline),
            detailLine: NoxEmotionalSafetyCopy.sanitize(detail),
            confidence: candidate.confidence,
            createdAt: candidate.createdAt,
            sourceSignals: candidate.sourceSignals
        )
    }

    private static func naturalHeadline(
        candidate: NoxReflectionCandidate,
        input: NoxReflectionInput,
        salience: NoxContinuitySalience
    ) -> String {
        let phrase: String
        switch candidate.id {
        case "reflection-resurfaced-arc":
            phrase = NoxContinuityPhraseAssembler.resurfacedArcPhrase(
                arcName: input.resurfacedArcLabels.first ?? input.dominantArcLabels.first,
                resumptions: input.continuityResumptions,
                salience: salience
            )
        case "reflection-fragmentation":
            phrase = NoxContinuityPhraseAssembler.fragmentationPhrase(
                fragmentedSessions: input.fragmentedSessions,
                salience: salience
            )
        case "reflection-behavioral-pattern":
            let detail = input.behavioralPatternDetails.first ?? candidate.text
            phrase = NoxContinuityPhraseAssembler.behavioralContinuityPhrase(
                patternDetail: detail,
                salience: salience
            )
        case "reflection-context-switching":
            let dev = input.semanticThemes.first { $0.lowercased().contains("development") } ?? "development"
            let research = input.semanticThemes.first { $0.lowercased().contains("research") } ?? "research"
            phrase = NoxContinuityPhraseAssembler.contextSwitchPhrase(development: dev, research: research)
        default:
            phrase = candidate.text
        }
        return NoxTemporalGroundingEngine.groundedHeadline(
            reflectionId: candidate.id,
            rawHeadline: phrase,
            input: input
        )
    }
}
