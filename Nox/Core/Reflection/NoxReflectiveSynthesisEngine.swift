import Foundation

enum NoxReflectiveSynthesisEngine {

    static let cooldownSeconds: TimeInterval = 6 * 3600
    static let minimumConfidence = 0.52
    static let displayLimit = 4

    static func shouldSynthesize(lastReflectionAt: Date?, at date: Date = Date()) -> Bool {
        guard let last = lastReflectionAt else { return true }
        return date.timeIntervalSince(last) >= cooldownSeconds
    }

    static func synthesize(input: NoxReflectionInput, at date: Date = Date()) -> [NoxReflectionCandidate] {
        var candidates: [NoxReflectionCandidate] = []

        if let resurfaced = resurfacedArcReflection(input, at: date) {
            candidates.append(resurfaced)
        }
        if let thread = recurringThreadReflection(input, at: date) {
            candidates.append(thread)
        }
        if let behavioral = behavioralContinuityReflection(input, at: date) {
            candidates.append(behavioral)
        }
        if let drift = driftObservationReflection(input, at: date) {
            candidates.append(drift)
        }
        if let structure = lifeStructureReflection(input, at: date) {
            candidates.append(structure)
        }
        if let switching = contextSwitchingReflection(input, at: date) {
            candidates.append(switching)
        }
        if let creative = creativeIntermittentReflection(input, at: date) {
            candidates.append(creative)
        }
        if let fragmentation = fragmentationReflection(input, at: date) {
            candidates.append(fragmentation)
        }
        if let horizon = weeklyHorizonReflection(input, at: date) {
            candidates.append(horizon)
        }
        if let focus = focusRhythmReflection(input, at: date) {
            candidates.append(focus)
        }

        return NoxReflectionPresenter.distinct(
            candidates
                .filter { $0.confidence >= minimumConfidence }
                .sorted { $0.confidence > $1.confidence },
            limit: displayLimit
        )
    }

    private static func resurfacedArcReflection(
        _ input: NoxReflectionInput,
        at date: Date
    ) -> NoxReflectionCandidate? {
        guard input.continuityResumptions >= 2 else { return nil }
        let arcName = input.resurfacedArcLabels.first ?? input.dominantArcLabels.first
        let text: String
        if let arcName {
            text = "\(arcName) picked up again after interruption — \(input.continuityResumptions) resumptions across recent sessions."
        } else {
            text = "Interrupted continuity picked up again — \(input.continuityResumptions) resumptions across recent sessions."
        }
        return candidate(
            id: "reflection-resurfaced-arc",
            text: text,
            detailLine: detail(
                "Semantic arcs and continuity threads from the last two weeks.",
                themes: input.resurfacedArcLabels + input.dominantArcLabels
            ),
            confidence: 0.6,
            signals: ["continuity_resumption", "semantic_arc"],
            at: date
        )
    }

    private static func recurringThreadReflection(
        _ input: NoxReflectionInput,
        at date: Date
    ) -> NoxReflectionCandidate? {
        guard let title = input.recurringThreadTitles.first else { return nil }
        let cleaned = title.replacingOccurrences(of: " continuity", with: "")
        let others = input.recurringThreadTitles.dropFirst().prefix(2)
        let text: String
        if others.isEmpty {
            text = "\(cleaned) has been a recurring continuity thread this \(input.periodLabel.lowercased())."
        } else {
            let also = others.map { $0.replacingOccurrences(of: " continuity", with: "") }.joined(separator: ", ")
            text = "\(cleaned) keeps returning alongside \(also) — recurring local threads, not goals."
        }
        return candidate(
            id: "reflection-recurring-thread",
            text: text,
            detailLine: "Thread recurrence inferred from resumptions and strength over ~14 days.",
            confidence: 0.57,
            signals: ["recurring_thread", cleaned],
            at: date
        )
    }

    private static func behavioralContinuityReflection(
        _ input: NoxReflectionInput,
        at date: Date
    ) -> NoxReflectionCandidate? {
        guard let label = input.behavioralPatternLabels.first else { return nil }
        let detailText = input.behavioralPatternDetails.first ?? label
        let rhythm = input.temporalRhythmLabels.first
        let rhythmDetail = input.temporalRhythmDetails.first
        var text = detailText
        if let rhythm, let rhythmDetail, !text.localizedCaseInsensitiveContains(rhythm) {
            text = "\(text) \(rhythmDetail)"
        } else if let rhythm {
            text = "\(text) (\(rhythm.lowercased()))."
        }
        return candidate(
            id: "reflection-behavioral-pattern",
            text: text,
            detailLine: "Probabilistic pattern from local activity density and cadence — observational.",
            confidence: 0.58,
            signals: ["behavioral_pattern", label],
            at: date
        )
    }

    private static func driftObservationReflection(
        _ input: NoxReflectionInput,
        at date: Date
    ) -> NoxReflectionCandidate? {
        guard let drift = input.driftObservation else { return nil }
        return candidate(
            id: "reflection-behavioral-drift",
            text: drift,
            detailLine: "Compared with your prior-week rhythm on this Mac — low certainty.",
            confidence: 0.55,
            signals: ["behavioral_drift"],
            at: date
        )
    }

    private static func lifeStructureReflection(
        _ input: NoxReflectionInput,
        at date: Date
    ) -> NoxReflectionCandidate? {
        guard let label = input.lifeStructureLabels.first else { return nil }
        let detailText = input.lifeStructureDetails.first ?? label
        return candidate(
            id: "reflection-life-structure",
            text: detailText,
            detailLine: "Soft era label (\(label)) — revisable if activity shifts.",
            confidence: 0.54,
            signals: ["life_structure", label],
            at: date
        )
    }

    private static func contextSwitchingReflection(
        _ input: NoxReflectionInput,
        at date: Date
    ) -> NoxReflectionCandidate? {
        let dev = input.semanticThemes.filter { $0.lowercased().contains("development") }
        let research = input.semanticThemes.filter { $0.lowercased().contains("research") }
        guard !dev.isEmpty, !research.isEmpty else { return nil }
        let devLabel = dev.first ?? "development"
        let researchLabel = research.first ?? "research"
        return candidate(
            id: "reflection-context-switching",
            text: "Sessions moved between \(devLabel.lowercased()) and \(researchLabel.lowercased()) — a familiar mix, not a score.",
            detailLine: "Themes from semantic memory spans over ~\(input.observationHours)h observed.",
            confidence: 0.62,
            signals: ["theme_mix", devLabel, researchLabel],
            at: date
        )
    }

    private static func creativeIntermittentReflection(
        _ input: NoxReflectionInput,
        at date: Date
    ) -> NoxReflectionCandidate? {
        guard let arc = input.dominantArcLabels.first(where: { $0.lowercased().contains("creative") }) else {
            return nil
        }
        return candidate(
            id: "reflection-creative-arc",
            text: "\(arc) appeared in bursts this week rather than as one long stretch.",
            detailLine: "Arc evolution from grouped semantic spans — intermittent, not failed focus.",
            confidence: 0.56,
            signals: ["creative_arc", arc],
            at: date
        )
    }

    private static func fragmentationReflection(
        _ input: NoxReflectionInput,
        at date: Date
    ) -> NoxReflectionCandidate? {
        guard input.fragmentedSessions >= 2 || input.focusSummary == "fragmented attention" else { return nil }
        return candidate(
            id: "reflection-fragmentation",
            text: "Attention split across \(input.fragmentedSessions) fragmented spans — context kept shifting.",
            detailLine: "From focus analysis and fragmented semantic states today.",
            confidence: 0.55,
            signals: ["fragmentation"],
            at: date
        )
    }

    private static func weeklyHorizonReflection(
        _ input: NoxReflectionInput,
        at date: Date
    ) -> NoxReflectionCandidate? {
        guard let snippet = input.weeklyHorizonSnippet,
              snippet.count >= 24 else { return nil }
        let trimmed = String(snippet.prefix(160))
        return candidate(
            id: "reflection-weekly-horizon",
            text: trimmed.hasSuffix(".") ? trimmed : "\(trimmed).",
            detailLine: "Compressed weekly rollup — summary only, no raw activity log.",
            confidence: 0.53,
            signals: ["weekly_rollup"],
            at: date
        )
    }

    private static func focusRhythmReflection(
        _ input: NoxReflectionInput,
        at date: Date
    ) -> NoxReflectionCandidate? {
        guard let focus = input.focusSummary else { return nil }
        return candidate(
            id: "reflection-focus-rhythm",
            text: "Today leaned toward \(focus) across \(input.observationHours) observed hours.",
            detailLine: "Focus blocks and switch density from local timeline — not a productivity grade.",
            confidence: 0.52,
            signals: ["focus_rhythm", focus],
            at: date
        )
    }

    private static func candidate(
        id: String,
        text: String,
        detailLine: String,
        confidence: Double,
        signals: [String],
        at date: Date
    ) -> NoxReflectionCandidate {
        NoxReflectionCandidate(
            id: id,
            text: NoxEmotionalSafetyCopy.sanitize(text),
            detailLine: NoxEmotionalSafetyCopy.sanitize(detailLine),
            confidence: confidence,
            createdAt: date,
            sourceSignals: signals
        )
    }

    private static func detail(_ base: String, themes: [String]) -> String {
        let unique = Array(Set(themes)).prefix(3)
        guard !unique.isEmpty else { return base }
        return "\(base) Themes: \(unique.joined(separator: ", "))."
    }
}
