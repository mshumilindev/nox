import Foundation
import NoxCore

/// Shape-based title analysis — no site or app hardcoding.
public enum NoxTitleTokenAnalyzer {
    public static func primarySegment(from title: String?) -> String? {
        guard let title, !title.isEmpty else { return nil }
        let separators = [" — ", " – ", " - ", " | ", " · "]
        for sep in separators {
            if let range = title.range(of: sep) {
                let left = String(title[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                if !left.isEmpty { return left }
            }
        }
        return title.trimmingCharacters(in: .whitespaces)
    }

    public static func secondarySegment(from title: String?) -> String? {
        guard let title, !title.isEmpty else { return nil }
        let separators = [" — ", " – ", " - ", " | ", " · "]
        for sep in separators {
            if let range = title.range(of: sep) {
                let right = String(title[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !right.isEmpty { return right }
            }
        }
        return nil
    }

    public static func indicatesPassiveMedia(title: String?) -> Bool {
        hasMediaShapeEvidence(title: title) || hasPassiveContentShapeEvidence(title: title)
    }

    public static func hasMediaShapeEvidence(title: String?) -> Bool {
        guard let title else { return false }
        let lower = title.lowercased()
        if lower.range(of: #"\d{1,2}:\d{2}"#, options: .regularExpression) != nil { return true }
        let tokens = [
            "episode", "season", "playing", "now playing", "▶", "⏸", "live stream",
            "music video", "official music video", "official video", "lyric video",
            "full concert", "live at", "vevo"
        ]
        return tokens.contains { lower.contains($0) }
    }

    public static func hasDocumentShapeEvidence(title: String?) -> Bool {
        guard let title else { return false }
        let extensions = [".pdf", ".doc", ".docx", ".md", ".txt", ".pages", ".key", ".numbers", ".xlsx"]
        let lower = title.lowercased()
        return extensions.contains { lower.contains($0) }
    }

    public static func hasProjectShapeEvidence(title: String?) -> Bool {
        guard let title else { return false }
        let markers = ["workspace", "project", "repository", "repo", "branch", "build", "debug"]
        let lower = title.lowercased()
        return markers.contains { lower.contains($0) }
    }

    public static func hasCommunicationShapeEvidence(title: String?) -> Bool {
        guard let title else { return false }
        let markers = ["#", "dm", "channel", "thread", "chat", "call", "meeting"]
        let lower = title.lowercased()
        return markers.contains { lower.contains($0) }
    }

    public static func hasTransferShapeEvidence(title: String?) -> Bool {
        guard let title else { return false }
        let markers = ["download", "upload", "transfer", "syncing", "seeding", "torrent", "%"]
        let lower = title.lowercased()
        return markers.contains { lower.contains($0) }
    }

    public static func looksLikeBrowserTabTitle(title: String?) -> Bool {
        guard let title, title.count > 3 else { return false }
        return secondarySegment(from: title) != nil || title.contains(".")
    }

    /// Passive media/content cues from title shape only — no host lists.
    public static func hasPassiveContentShapeEvidence(title: String?) -> Bool {
        guard let title else { return false }
        let lower = title.lowercased()
        let markers = [
            "live", "official video", "official music video", "full episode", "trailer",
            "documentary", "concert", "performance", "semifinal", "final", "soundtrack",
            "podcast", "playlist", "remix", "lyrics", "mv ", " ft ", " feat ", " - youtube"
        ]
        if markers.contains(where: { lower.contains($0) }) { return true }
        if lower.range(of: #"\(\d{4}\)"#, options: .regularExpression) != nil { return true }
        if hasMediaShapeEvidence(title: title) { return true }
        return false
    }
}
