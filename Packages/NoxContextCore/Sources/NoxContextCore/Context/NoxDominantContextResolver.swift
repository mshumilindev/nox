import Foundation
import NoxCore

/// Resolves dominant vs secondary vs stale context using temporal dominance rules.
public final class NoxDominantContextResolver: @unchecked Sendable {
    public init() {}

    private var currentDominant: NoxDominantContextType?
    private var dominantSince: Date?
    private var lastEvaluationAt: Date?

    public struct Resolution: Equatable, Sendable {
        public let dominant: NoxContextCandidate?
        public let secondary: [NoxContextCandidate]
        public let staleIgnored: [NoxContextCandidate]
        public let dominanceScore: Double
        public let reasons: [NoxContextReason]
        public let supportingSignals: [String]
        public let ignoredSignals: [String]

        public init(
            dominant: NoxContextCandidate?,
            secondary: [NoxContextCandidate],
            staleIgnored: [NoxContextCandidate],
            dominanceScore: Double,
            reasons: [NoxContextReason],
            supportingSignals: [String],
            ignoredSignals: [String]
        ) {
            self.dominant = dominant
            self.secondary = secondary
            self.staleIgnored = staleIgnored
            self.dominanceScore = dominanceScore
            self.reasons = reasons
            self.supportingSignals = supportingSignals
            self.ignoredSignals = ignoredSignals
        }
    }

    public func resolve(
        ranked: [NoxContextCandidate],
        input: NoxContextAdapterInput,
        adapterReasons: [NoxContextReason],
        at date: Date = Date()
    ) -> Resolution {
        guard !ranked.isEmpty else {
            return Resolution(
                dominant: nil,
                secondary: [],
                staleIgnored: [],
                dominanceScore: 0,
                reasons: adapterReasons,
                supportingSignals: [],
                ignoredSignals: ["no-candidates"]
            )
        }

        let top = ranked[0]
        var reasons = adapterReasons
        var ignored: [String] = []
        var stale: [NoxContextCandidate] = []

        if let previous = currentDominant, previous != top.contextType {
            let held = dominantSince.map { date.timeIntervalSince($0) } ?? 0
            if shouldRetainPrevious(
                previous: previous,
                challenger: top.contextType,
                heldSeconds: held,
                input: input,
                ranked: ranked
            ) {
                if let retained = ranked.first(where: { $0.contextType == previous }) {
                    reasons.append(.init(
                        category: "dominance",
                        detail: "Previous dominant context retained (stability)",
                        weight: 0.7
                    ))
                    let secondary = ranked.filter { $0.contextType != previous }
                    stale = secondary.filter { isStale($0, input: input) }
                    ignored = stale.flatMap(\.signalNames)
                    return Resolution(
                        dominant: retained,
                        secondary: secondary.filter { !isStale($0, input: input) },
                        staleIgnored: stale,
                        dominanceScore: retained.dominanceWeight,
                        reasons: reasons,
                        supportingSignals: retained.signalNames,
                        ignoredSignals: ignored
                    )
                }
            }
        }

        if currentDominant != top.contextType {
            currentDominant = top.contextType
            dominantSince = date
        }
        lastEvaluationAt = date

        let secondary = Array(ranked.dropFirst().prefix(3))
        stale = ranked.filter { isStale($0, input: input) && $0.contextType != top.contextType }
        ignored = stale.flatMap(\.signalNames)

        reasons.append(.init(
            category: "dominance",
            detail: "Dominant context: \(top.contextType.rawValue)",
            weight: top.dominanceWeight
        ))

        return Resolution(
            dominant: top,
            secondary: secondary,
            staleIgnored: stale,
            dominanceScore: top.dominanceWeight,
            reasons: reasons,
            supportingSignals: top.signalNames,
            ignoredSignals: ignored
        )
    }

    public func reset() {
        currentDominant = nil
        dominantSince = nil
        lastEvaluationAt = nil
    }

    private func shouldRetainPrevious(
        previous: NoxDominantContextType,
        challenger: NoxDominantContextType,
        heldSeconds: TimeInterval,
        input: NoxContextAdapterInput,
        ranked: [NoxContextCandidate]
    ) -> Bool {
        let challengerScore = ranked.first(where: { $0.contextType == challenger })?.dominanceWeight ?? 0
        let previousScore = ranked.first(where: { $0.contextType == previous })?.dominanceWeight ?? 0
        let margin = challengerScore - previousScore

        // Sustained passive media/content can overtake fragmented workflow.
        if isPassiveMediaLike(challenger), isFragmentedWorkflowLike(previous) {
            return input.stableDurationSeconds < 35 || margin < 0.08
        }

        if isPassiveMediaLike(challenger), previous == .research || previous == .reading {
            return input.stableDurationSeconds < 25 && margin < 0.1
        }

        // Sustained writing overtakes passive browsing/reading.
        if challenger == .writing || challenger == .development {
            if previous == .reading || previous == .research {
                return !input.metrics.isWritingHeavy && heldSeconds > 20 && margin < 0.15
            }
        }

        // Creative sustained work overtakes research.
        if challenger == .creativeWork, previous == .research || previous == .reading {
            return input.stableDurationSeconds < 50 && margin < 0.1
        }

        // Terminal/build should not collapse to idle unknown.
        if previous == .development, challenger == .unknown || challenger == .insufficient {
            return true
        }

        // Background listening should not beat active foreground dev.
        if challenger == .listening || challenger == .watching {
            if previous == .development && input.metrics.isWritingHeavy {
                return true
            }
            if previous == .development && !input.snapshot.isIdle && input.metrics.isInteractionActive {
                return margin < 0.2
            }
        }

        return heldSeconds < 25 && margin < 0.18
    }

    private func isPassiveMediaLike(_ type: NoxDominantContextType) -> Bool {
        type == .watching || type == .listening
    }

    private func isFragmentedWorkflowLike(_ type: NoxDominantContextType) -> Bool {
        type == .research || type == .writing || type == .development || type == .shoppingComparison
    }

    private func isStale(_ candidate: NoxContextCandidate, input: NoxContextAdapterInput) -> Bool {
        guard let dominant = currentDominant else { return false }
        if candidate.contextType == dominant { return false }
        if input.stableDurationSeconds > 120 && candidate.confidence < 0.45 {
            return true
        }
        return candidate.confidence < 0.35
    }
}
