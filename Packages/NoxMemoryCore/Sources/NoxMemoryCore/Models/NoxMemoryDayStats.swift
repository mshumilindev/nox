import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

public struct NoxMemoryDayStats: Equatable, Sendable {
    public let periodLabel: String
    public let totalActiveMs: Int
    public let focusedMs: Int
    public let fragmentedMs: Int
    public let appSwitchCount: Int
    public let longestFocusBlockMs: Int
    public let dominantApp: String?
    public let dominantCategory: NoxActivityCategory?

    public init(
        periodLabel: String,
        totalActiveMs: Int,
        focusedMs: Int,
        fragmentedMs: Int,
        appSwitchCount: Int,
        longestFocusBlockMs: Int,
        dominantApp: String? = nil,
        dominantCategory: NoxActivityCategory? = nil
    ) {
        self.periodLabel = periodLabel
        self.totalActiveMs = totalActiveMs
        self.focusedMs = focusedMs
        self.fragmentedMs = fragmentedMs
        self.appSwitchCount = appSwitchCount
        self.longestFocusBlockMs = longestFocusBlockMs
        self.dominantApp = dominantApp
        self.dominantCategory = dominantCategory
    }

    public static let empty = NoxMemoryDayStats(
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
