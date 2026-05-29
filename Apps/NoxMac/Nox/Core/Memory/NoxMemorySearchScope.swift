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

/// Narrows timeline layers to filter hits so search and dedup use the same time scope.
enum NoxMemorySearchScope {

    static func isActive(query: NoxMemoryQuery, period: NoxMemoryPeriod) -> Bool {
        !query.isEmpty && !query.matches(period: period)
    }

    static func continuityMatches(_ thread: NoxContinuityThread, query: String, windows: [NoxTimeInterval]) -> Bool {
        let normalized = query.lowercased()
        if thread.title.lowercased().contains(normalized) { return true }
        if thread.dominantApps.contains(where: { $0.lowercased().contains(normalized) }) { return true }
        let interval = NoxTimeInterval(start: thread.firstSeenAt, end: thread.lastSeenAt)
        return NoxTimeIntervalMerge.intersectsAny(interval, windows: windows)
    }

    static func interruptionMatches(_ interruption: NoxInterruption, query: String) -> Bool {
        let normalized = query.lowercased()
        return interruption.fromApp.lowercased().contains(normalized)
            || interruption.toApp.lowercased().contains(normalized)
    }

    static func focusMatches(_ block: NoxFocusBlock, windows: [NoxTimeInterval]) -> Bool {
        let interval = NoxTimeInterval(start: block.startedAt, end: block.endedAt)
        return NoxTimeIntervalMerge.intersectsAny(interval, windows: windows)
    }
}
