import Foundation

enum NoxReflectiveSynthesisEngine {

    static let cooldownSeconds: TimeInterval = 6 * 3600
    static let minimumConfidence = 0.52

    static func shouldSynthesize(lastReflectionAt: Date?, at date: Date = Date()) -> Bool {
        guard let last = lastReflectionAt else { return true }
        return date.timeIntervalSince(last) >= cooldownSeconds
    }

    static func synthesize(input: NoxReflectionInput, at date: Date = Date()) -> [NoxReflectionCandidate] {
        var candidates: [NoxReflectionCandidate] = []

        if let switching = contextSwitchingReflection(input) {
            candidates.append(switching)
        }
        if let creative = creativeIntermittentReflection(input) {
            candidates.append(creative)
        }
        if let resurfaced = resurfacedArcReflection(input) {
            candidates.append(resurfaced)
        }
        if let rhythm = recurringThreadReflection(input) {
            candidates.append(rhythm)
        }

        return candidates
            .filter { $0.confidence >= minimumConfidence }
            .prefix(2)
            .map { $0 }
    }

    private static func contextSwitchingReflection(_ input: NoxReflectionInput) -> NoxReflectionCandidate? {
        let dev = input.semanticThemes.filter { $0.lowercased().contains("development") }.count
        let research = input.semanticThemes.filter { $0.lowercased().contains("research") }.count
        guard dev >= 1, research >= 1 else { return nil }

        return NoxReflectionCandidate(
            id: UUID().uuidString,
            text: "Recent sessions suggest recurring context switching between development and research.",
            confidence: 0.62,
            createdAt: Date(),
            sourceSignals: ["theme_mix", "development", "research"]
        )
    }

    private static func creativeIntermittentReflection(_ input: NoxReflectionInput) -> NoxReflectionCandidate? {
        guard input.dominantArcLabels.contains(where: { $0.lowercased().contains("creative") }) else {
            return nil
        }
        return NoxReflectionCandidate(
            id: UUID().uuidString,
            text: "Creative-focused continuity appeared intermittently this week.",
            confidence: 0.56,
            createdAt: Date(),
            sourceSignals: ["creative_arc"]
        )
    }

    private static func resurfacedArcReflection(_ input: NoxReflectionInput) -> NoxReflectionCandidate? {
        guard input.continuityResumptions >= 2 else { return nil }
        return NoxReflectionCandidate(
            id: UUID().uuidString,
            text: "A previously interrupted project arc resurfaced multiple times.",
            confidence: 0.58,
            createdAt: Date(),
            sourceSignals: ["continuity_resumption"]
        )
    }

    private static func recurringThreadReflection(_ input: NoxReflectionInput) -> NoxReflectionCandidate? {
        guard let title = input.recurringThreadTitles.first else { return nil }
        let cleaned = title.replacingOccurrences(of: " continuity", with: "")
        return NoxReflectionCandidate(
            id: UUID().uuidString,
            text: "\(cleaned) has appeared as a recurring continuity thread.",
            confidence: 0.54,
            createdAt: Date(),
            sourceSignals: ["recurring_thread"]
        )
    }
}
