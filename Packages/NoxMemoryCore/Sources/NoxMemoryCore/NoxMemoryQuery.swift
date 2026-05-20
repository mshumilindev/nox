import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

public struct NoxMemoryQuery: Sendable {
    public let text: String
    public let period: NoxMemoryPeriod

    public init(text: String, period: NoxMemoryPeriod) {
        self.text = text
        self.period = period
    }

    public var normalizedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    public var isEmpty: Bool {
        normalizedText.isEmpty
    }

    public func matches(period: NoxMemoryPeriod) -> Bool {
        switch normalizedText {
        case "today":
            return period == .today
        case "yesterday":
            return period == .yesterday
        default:
            return false
        }
    }
}
