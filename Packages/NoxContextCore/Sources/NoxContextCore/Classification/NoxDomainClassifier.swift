import Foundation
import NoxCore

public struct NoxDomainClassifier {
    public init() {}

    public func domain(from windowTitle: String?, documentURL: String? = nil) -> String? {
        if let documentURL, !documentURL.isEmpty, let url = URL(string: documentURL) {
            return host(from: url)
        }
        guard let title = windowTitle, !title.isEmpty else { return nil }
        if let url = extractURL(from: title) {
            return host(from: url)
        }
        return nil
    }

    public func normalizedSiteName(domain: String?) -> String? {
        guard let domain else { return nil }
        return domain
            .replacingOccurrences(of: "www.", with: "")
            .split(separator: ".")
            .first
            .map { $0.capitalized }
    }

    private func extractURL(from text: String) -> URL? {
        let pattern = #"https?://[^\s]+"#
        guard let range = text.range(of: pattern, options: .regularExpression) else { return nil }
        return URL(string: String(text[range]))
    }

    private func host(from url: URL) -> String? {
        url.host?.lowercased()
    }
}
