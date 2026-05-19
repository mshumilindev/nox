import Foundation

struct NoxMemoryQuery: Sendable {
    let text: String
    let period: NoxMemoryPeriod

    var normalizedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var isEmpty: Bool {
        normalizedText.isEmpty
    }

    func matches(period: NoxMemoryPeriod) -> Bool {
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
