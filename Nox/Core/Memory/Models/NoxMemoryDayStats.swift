import Foundation

struct NoxMemoryDayStats: Equatable, Sendable {
    let periodLabel: String
    let totalActiveMs: Int
    let focusedMs: Int
    let fragmentedMs: Int
    let appSwitchCount: Int
    let longestFocusBlockMs: Int
    let dominantApp: String?
    let dominantCategory: NoxActivityCategory?

    static let empty = NoxMemoryDayStats(
        periodLabel: "Today",
        totalActiveMs: 0,
        focusedMs: 0,
        fragmentedMs: 0,
        appSwitchCount: 0,
        longestFocusBlockMs: 0,
        dominantApp: nil,
        dominantCategory: nil
    )
}
