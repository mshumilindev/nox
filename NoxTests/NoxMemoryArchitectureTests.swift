import Foundation
import Testing
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
@testable import Nox

struct NoxMemoryRollupStoreTests {

    private func isolatedDatabaseURL() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("nox-rollup-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("timeline.db")
    }

    @Test func rollupRoundTrip() async throws {
        let store = NoxMemoryRollupStore(databaseURL: try isolatedDatabaseURL())
        try await store.open()

        let start = Calendar.current.startOfDay(for: Date().addingTimeInterval(-86_400))
        let end = start.addingTimeInterval(86_400)
        let facts = NoxRollupFacts(totalActiveMs: 120_000, sessionCount: 1)
        let snapshot = NoxDeterministicRollupEngine.makeSnapshot(
            level: .daily,
            periodStart: start,
            periodEnd: end,
            facts: facts
        )
        try await store.upsert(snapshot)

        #expect(try await store.exists(level: .daily, periodStart: start))
        let loaded = try await store.rollup(level: .daily, periodStart: start)
        #expect(loaded?.facts.totalActiveMs == 120_000)
    }
}
