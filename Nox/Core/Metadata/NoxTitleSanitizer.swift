import Foundation

enum NoxTitleSanitizer {
    static func sanitize(appName: String, windowTitle: String?) -> String? {
        guard var title = windowTitle?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            return nil
        }

        let suffixPatterns = [
            " — \(appName)",
            " - \(appName)",
            " – \(appName)",
            " | \(appName)",
            " — Edited",
            " - Edited"
        ]
        var changed = true
        while changed {
            changed = false
            for pattern in suffixPatterns {
                if title.hasSuffix(pattern) {
                    title = String(title.dropLast(pattern.count))
                    changed = true
                }
            }
        }

        if title.lowercased().hasPrefix("github") {
            return simplifyGitHubTitle(title)
        }

        return title.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private static func simplifyGitHubTitle(_ title: String) -> String {
        if title.lowercased().contains("pull request") {
            return "GitHub · Pull Request"
        }
        if title.contains("/") {
            return "GitHub · Repository"
        }
        return "GitHub"
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
