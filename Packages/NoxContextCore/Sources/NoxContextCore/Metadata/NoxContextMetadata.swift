import Foundation
import NoxCore

public struct NoxContextMetadata: Codable, Equatable, Sendable {
    public let contextLabel: String?
    public let projectName: String?
    public let domain: String?
    public let siteName: String?
    public let category: NoxActivityCategory
    public let rawWindowTitle: String?

    public init(
        contextLabel: String?,
        projectName: String?,
        domain: String?,
        siteName: String?,
        category: NoxActivityCategory,
        rawWindowTitle: String?
    ) {
        self.contextLabel = contextLabel
        self.projectName = projectName
        self.domain = domain
        self.siteName = siteName
        self.category = category
        self.rawWindowTitle = rawWindowTitle
    }

    public static let empty = NoxContextMetadata(
        contextLabel: nil,
        projectName: nil,
        domain: nil,
        siteName: nil,
        category: .general,
        rawWindowTitle: nil
    )
}

public struct NoxMetadataExtractor {
    public init() {}

    private let classifier = NoxAppClassifier()
    private let domainClassifier = NoxDomainClassifier()

    public func extract(appName: String, bundleId: String, windowTitle: String?) -> NoxContextMetadata {
        let category = classifier.classify(bundleId: bundleId, appName: appName, windowTitle: windowTitle)
        let sanitized = NoxTitleSanitizer.sanitize(appName: appName, windowTitle: windowTitle)
        let domain = domainClassifier.domain(from: windowTitle)
        let siteName = domainClassifier.normalizedSiteName(domain: domain)
        let contentTitle = contentTitle(
            sanitizedTitle: sanitized,
            appName: appName,
            siteName: siteName
        )
        let projectName = projectName(appName: appName, bundleId: bundleId, sanitizedTitle: sanitized)

        let contextLabel = contextLabel(
            appName: appName,
            sanitizedTitle: contentTitle ?? sanitized,
            projectName: projectName,
            siteName: siteName
        )

        return NoxContextMetadata(
            contextLabel: contextLabel,
            projectName: projectName,
            domain: domain,
            siteName: siteName,
            category: category,
            rawWindowTitle: windowTitle
        )
    }

    private func projectName(appName: String, bundleId: String, sanitizedTitle: String?) -> String? {
        let ideBundles: Set<String> = [
            "com.apple.dt.Xcode",
            "com.microsoft.VSCode",
            "com.todesktop.230313mzl4w4u92",
            "com.jetbrains.webstorm"
        ]
        guard ideBundles.contains(bundleId), let sanitizedTitle else { return nil }
        return sanitizedTitle
    }

    private func contextLabel(
        appName: String,
        sanitizedTitle: String?,
        projectName: String?,
        siteName: String?
    ) -> String? {
        if let projectName { return projectName }
        if let sanitizedTitle, sanitizedTitle != appName { return sanitizedTitle }
        if let siteName { return siteName }
        // nil — caller already knows the app; avoids "Cursor · Cursor" style duplicates.
        return nil
    }

    private func contentTitle(
        sanitizedTitle: String?,
        appName: String,
        siteName: String?
    ) -> String? {
        guard var title = sanitizedTitle?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            return nil
        }

        title = title.replacingOccurrences(
            of: #"^\(\d+\)\s*"#,
            with: "",
            options: .regularExpression
        )

        for suffix in [siteName, appName].compactMap({ $0 }).filter({ !$0.isEmpty }) {
            let patterns = [
                " - \(suffix)",
                " — \(suffix)",
                " – \(suffix)",
                " | \(suffix)"
            ]
            var changed = true
            while changed {
                changed = false
                for pattern in patterns where title.localizedCaseInsensitiveContains(pattern) && title.hasSuffix(pattern) {
                    title = String(title.dropLast(pattern.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                    changed = true
                }
            }
        }

        return title.isEmpty ? nil : title
    }
}
