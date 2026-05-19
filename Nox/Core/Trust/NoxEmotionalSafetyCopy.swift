import Foundation

/// Guardrails against manipulative or surveillance-toned product copy.
enum NoxEmotionalSafetyCopy {

    static let forbiddenSubstrings = [
        "productive",
        "productivity score",
        "bad habit",
        "streak",
        "goal",
        "optimize yourself",
        "tracking you",
        "purge",
        "surveillance"
    ]

    static func sanitize(_ text: String) -> String {
        let lower = text.lowercased()
        for forbidden in forbiddenSubstrings where lower.contains(forbidden) {
            return "Recent context is forming calmly."
        }
        return text
    }

    static func isAllowed(_ text: String) -> Bool {
        sanitize(text) == text
    }
}
