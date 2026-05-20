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
                "Recurring activity threads and reflections",
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
                "Sensitive activity is generalized before long-term storage",
                "Titles and domains may be redacted before memory"
            ]
        ),
        NoxTrustSection(
            id: "retention",
            title: "Memory retention",
            lines: [
                "Short-term activity detail is automatically reduced over time",
                "Older activity is compressed into higher-level summaries",
                "You can clear recent activity at any time"
            ]
        ),
        NoxTrustSection(
            id: "generalization",
            title: "Activity generalization",
            lines: [
                "Private contexts become generalized activity summaries",
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
                "You can pause pattern detection or enter quiet mode"
            ]
        ),
        NoxTrustSection(
            id: "connectors",
            title: "Connector awareness",
            lines: [
                "Calendar and communication signals stay generalized",
                "Meeting titles and message bodies are not stored",
                "Each connector category can be disabled independently",
                "Connector-derived activity can be cleared locally"
            ]
        )
    ]
}
