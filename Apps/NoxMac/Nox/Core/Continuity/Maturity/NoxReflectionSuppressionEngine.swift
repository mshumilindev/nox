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

nonisolated enum NoxReflectionSuppressionEngine {

    private static let marginalConfidence = 0.56
    private static let recentSimilarityHours: TimeInterval = 48 * 3600

    static func shouldSuppress(
        matured: NoxMaturedReflection,
        stored: [NoxReflectionCandidate],
        context: NoxContinuityMaturityContext,
        at date: Date = Date()
    ) -> Bool {
        let candidate = matured.candidate

        if matured.gravity < 0.44 && candidate.confidence < 0.58 {
            return true
        }

        if candidate.confidence < marginalConfidence && matured.gravity < 0.52 {
            return true
        }

        if isSemanticallySimilar(candidate.text, to: stored, after: date.addingTimeInterval(-recentSimilarityHours)) {
            return true
        }

        if candidate.id == "reflection-weekly-horizon",
           matured.gravity < 0.52,
           context.input.weeklyHorizonSnippet?.count ?? 0 < 40 {
            return true
        }

        if candidate.id == "reflection-focus-rhythm", matured.gravity < 0.48 {
            return true
        }

        if candidate.id == "reflection-life-structure", matured.gravity < 0.5 {
            return true
        }

        if candidate.id == "reflection-behavioral-pattern",
           context.behavioral.signatures.isEmpty {
            return true
        }

        return false
    }

    static func displayLimit(topGravity: Double) -> Int {
        topGravity >= 0.72 ? 3 : 2
    }

    private static func isSemanticallySimilar(
        _ text: String,
        to stored: [NoxReflectionCandidate],
        after: Date
    ) -> Bool {
        let normalized = normalize(text)
        guard normalized.count >= 24 else { return false }
        for prior in stored where prior.createdAt >= after {
            let priorNorm = normalize(prior.text)
            if priorNorm == normalized { return true }
            if normalized.count > 40, priorNorm.count > 40,
               normalized.hasPrefix(String(priorNorm.prefix(48))) {
                return true
            }
        }
        return false
    }

    private static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
