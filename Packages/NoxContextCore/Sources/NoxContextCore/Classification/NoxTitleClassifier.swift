import Foundation
import NoxCore

nonisolated public struct NoxTitleClassifier {
    public init() {}

    public func refineBrowserCategory(title: String, defaultCategory: NoxActivityCategory) -> NoxActivityCategory {
        let lower = title.lowercased()
        if lower.contains("chatgpt") || lower.contains("openai") { return .research }
        if lower.contains("github") { return .development }
        if lower.contains("stackoverflow") || lower.contains("docs") || lower.contains("api") {
            return .research
        }
        if lower.contains("youtube") {
            return lower.contains("tutorial") || lower.contains("course") ? .research : .passive
        }
        if lower.contains("slack") || lower.contains("discord") { return .communication }
        return defaultCategory
    }

    public func isWorkLikeBrowser(title: String) -> Bool {
        refineBrowserCategory(title: title, defaultCategory: .research).isWorkLike
    }
}
