import Foundation
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore
import NoxShrineCore

/// Lightweight day-level framing — shape of the day, not analytics.
enum NoxDaySemanticFraming {

    static func overview(
        blocks: [NoxTimelineBlockItem],
        stats: NoxMemoryDayStats,
        continuityThreads: [NoxContinuityThread] = []
    ) -> String? {
        guard stats.totalActiveMs > 0 else { return nil }

        if !continuityThreads.isEmpty {
            return continuityOverview(threads: continuityThreads, blocks: blocks, stats: stats)
        }

        let semantic = blocks.compactMap { item -> NoxSemanticMemorySpan? in
            if case .semanticSpan(let span) = item.kind { return span }
            return nil
        }

        if semantic.isEmpty {
            return lowActivityOverview(stats: stats)
        }

        let titles = semantic.map(\.title).map { $0.lowercased() }
        let fragmented = titles.filter { $0.contains("fragmented") || $0.contains("several contexts") }.count
        let dev = titles.filter { $0.contains("development") || $0.contains("ai-assisted") }.count
        let research = titles.filter { $0.contains("research") || $0.contains("reading") }.count
        let passive = titles.filter { $0.contains("passive") || $0.contains("viewing") || $0.contains("watching") }.count
        let travel = titles.filter { $0.contains("travel") }.count

        if dev >= 2 || (dev >= 1 && research >= 1) {
            return "Today mixed development and research."
        }
        if travel >= 1 && research >= 1 {
            return "Today mixed travel planning with research browsing."
        }
        if fragmented >= 2 || stats.appSwitchCount >= 12 {
            return "Several contexts moved through the day."
        }
        if passive >= 2 && stats.focusedMs < stats.totalActiveMs / 3 {
            return "A quieter day — mostly watching and reading."
        }
        if research >= 2 {
            return "Today leaned toward research and reading."
        }
        if stats.focusedMs > stats.totalActiveMs / 2 {
            return "Longer stretches of steady context today."
        }
        return NoxHumanContextCopy.todayBeginningToTakeShape
    }

    private static func continuityOverview(
        threads: [NoxContinuityThread],
        blocks: [NoxTimelineBlockItem],
        stats: NoxMemoryDayStats
    ) -> String? {
        let resumedToday = threads.filter { $0.totalResumptions > 0 && $0.currentStatus == .resumed }.count
        let dev = threads.filter { $0.semanticType == .aiDevelopment || $0.semanticType == .development }.count
        let research = threads.filter { $0.semanticType == .research }.count
        let fragmented = threads.filter { $0.semanticType == .fragmentedWorkflow }.count

        if dev >= 1 && resumedToday >= 2 {
            return "Development context returned several times today."
        }
        if research >= 1 && resumedToday >= 1 {
            return "Research activity appeared repeatedly today."
        }
        if fragmented >= 2 {
            return "Attention moved between several contexts today."
        }
        if threads.count >= 2 {
            return "Several distinct activity threads appeared today."
        }
        if let first = threads.first {
            let name = first.title.replacingOccurrences(of: " continuity", with: "")
            return "\(name) activity appeared throughout the day."
        }
        return overview(blocks: blocks, stats: stats, continuityThreads: [])
    }

    private static func lowActivityOverview(stats: NoxMemoryDayStats) -> String {
        if stats.totalActiveMs < 15 * 60_000 {
            return "A quiet day so far."
        }
        return NoxHumanContextCopy.todayBeginningToTakeShape
    }
}
