import Foundation

nonisolated enum NoxReflectiveLanguageSoftener {

    static func soften(_ text: String) -> String {
        var result = text
        for (pattern, replacement) in replacements {
            result = result.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: [.caseInsensitive]
            )
        }
        return collapseWhitespace(result)
    }

    static func softenDetail(_ text: String) -> String {
        var result = soften(text)
        let analyticalPhrases = [
            "probabilistic pattern",
            "observational, not prescriptive",
            "semantic arcs",
            "continuity threads",
            "soft era label",
            "revisable if activity shifts",
            "arc evolution from grouped semantic spans",
            "thread recurrence inferred",
            "not a productivity grade",
            "not a score",
            "low certainty"
        ]
        for phrase in analyticalPhrases where result.localizedCaseInsensitiveContains(phrase) {
            result = result.replacingOccurrences(of: phrase, with: "", options: .caseInsensitive)
        }
        return collapseWhitespace(result.trimmingCharacters(in: CharacterSet(charactersIn: "—-· ")))
    }

    private static let replacements: [(String, String)] = [
        ("fragmented context period", "stretch where attention kept breaking apart"),
        ("deep-focus streak", "longer stretches of sustained focus"),
        ("coordination-heavy stretch", "a week shaped by scheduling and back-and-forth"),
        ("coordination-heavy era", "a stretch with more coordination than usual"),
        ("overload–recovery oscillation", "fuller days followed by quieter ones"),
        ("overload-recovery oscillation", "fuller days followed by quieter ones"),
        ("oscillating cadence", "rhythm that keeps shifting between density and quiet"),
        ("instability phase", "less settled rhythm than usual"),
        ("passive decompression loop", "more passive listening or viewing than work"),
        ("creative exploration phase", "creative work appearing in bursts"),
        ("late-night work cycle", "evening work showing up again"),
        ("continuity thread", "activity thread"),
        ("continuity threads", "activity threads"),
        ("semantic arc", "activity thread"),
        ("semantic arcs", "activity threads"),
        ("continuity", "activity"),
        ("merging", "increasing overlap"),
        ("emerging", "recently forming"),
        ("resumptions", "returns"),
        ("resumption", "return"),
        ("detected", "noticed"),
        ("observed locally", "noticed on this Mac"),
        ("pattern from local activity density", "from recent activity on this Mac"),
        ("behavioral pattern", "recent rhythm"),
        ("life-shaped", "longer-running"),
        ("era label", "stretch"),
        ("familiar mix, not a score", "familiar back-and-forth"),
        ("recurring local threads, not goals", "recurring through-lines"),
        ("intermittent, not failed focus", "in bursts rather than one long stretch")
    ]

    private static func collapseWhitespace(_ text: String) -> String {
        text
            .replacingOccurrences(of: "  ", with: " ")
            .replacingOccurrences(of: " .", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
