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

struct NoxMemoryControlReport: Equatable, Sendable {
    let clearedSpans: Int
    let clearedSemantic: Int
    let clearedThreads: Int
}

@MainActor
final class NoxMemoryControlCoordinator {
    private let memoryCoordinator: NoxMemoryCoordinator
    private let timelineStore: NoxTimelineStore

    init(
        memoryCoordinator: NoxMemoryCoordinator,
        timelineStore: NoxTimelineStore
    ) {
        self.memoryCoordinator = memoryCoordinator
        self.timelineStore = timelineStore
    }

    func clearRecentMemory(hours: Int = 48) async throws -> NoxMemoryControlReport {
        let end = Date()
        let start = end.addingTimeInterval(-Double(hours) * 3600)
        let spans = try await memoryCoordinator.clearRecentActivity(from: start, to: end)
        let events = try await timelineStore.deleteEvents(from: start, to: end)
        _ = events
        return NoxMemoryControlReport(
            clearedSpans: spans,
            clearedSemantic: 0,
            clearedThreads: 0
        )
    }

    func clearSemanticContinuity() async throws -> NoxMemoryControlReport {
        let semantic = try await memoryCoordinator.clearAllSemanticMemory()
        let threads = try await memoryCoordinator.clearAllContinuityThreads()
        return NoxMemoryControlReport(
            clearedSpans: 0,
            clearedSemantic: semantic,
            clearedThreads: threads
        )
    }
}
