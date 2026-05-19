import Foundation

struct NoxTrustSection: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let lines: [String]
}

enum NoxTrustContent {

    static let localBadge = "Runs locally on this Mac"

    static let sections: [NoxTrustSection] = [
        NoxTrustSection(
            id: "stored",
            title: "Stored locally",
            lines: [
                "Activity spans and calm semantic summaries",
                "Continuity threads and reflections",
                "Presence and session rhythm metadata"
            ]
        ),
        NoxTrustSection(
            id: "never",
            title: "Never collected",
            lines: [
                "Typed text is never stored",
                "Browser contents are not recorded",
                "No screenshots or screen replay",
                "No clipboard history",
                "No keystroke recording"
            ]
        ),
        NoxTrustSection(
            id: "sensitive",
            title: "Sensitive contexts",
            lines: [
                "Banking, adult, and private browsing are generalized",
                "Sensitive continuity stores shape — not detail",
                "Titles and domains may be redacted before memory"
            ]
        ),
        NoxTrustSection(
            id: "retention",
            title: "Memory retention",
            lines: [
                "Warm timeline noise is pruned on a schedule",
                "Compressed horizons age into calmer summaries",
                "You can clear recent continuity at any time"
            ]
        ),
        NoxTrustSection(
            id: "generalization",
            title: "Semantic generalization",
            lines: [
                "Private contexts become generalized continuity",
                "Reflections avoid inventing detail",
                "Ambiguity is preserved when confidence is low"
            ]
        ),
        NoxTrustSection(
            id: "reflections",
            title: "Reflection boundaries",
            lines: [
                "Reflections are infrequent and cooldown-protected",
                "No coaching, scoring, or optimization language",
                "You can pause continuity or enter a quiet mode"
            ]
        )
    ]
}
