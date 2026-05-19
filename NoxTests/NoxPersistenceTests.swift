import Foundation
import Testing
@testable import Nox

struct NoxPersistencePathsTests {

    @Test func databaseURLIsStableApplicationSupportPath() {
        let url = NoxPersistencePaths.databaseURL
        #expect(url.path.contains("Application Support"))
        #expect(url.path.contains("Nox"))
        #expect(url.lastPathComponent == "timeline.db")
        #expect(url == NoxPersistencePaths.databaseURL)
    }
}

struct NoxSessionPersistenceTests {

    private func isolatedDatabaseURL() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("nox-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("timeline.db")
    }

    @Test func activeSessionRoundTripAndInterruptClose() async throws {
        let dbURL = try isolatedDatabaseURL()
        let store = NoxSessionStore(databaseURL: dbURL)
        try await store.open()

        let sessionId = "test-\(UUID().uuidString)"
        let session = NoxWorkSession(
            id: sessionId,
            startedAt: Date().addingTimeInterval(-120),
            endedAt: nil,
            primaryApp: "Xcode",
            primaryBundleId: "com.apple.dt.Xcode",
            interruptionCount: 0,
            appSwitchCount: 1,
            confidence: 0.75,
            state: .active
        )
        try await store.upsert(session)

        let active = try await store.activeSession()
        #expect(active?.id == sessionId)

        try await store.closeActiveSessions(at: Date(), reason: .interruptedByRestart)
        #expect(try await store.activeSession() == nil)

        let ended = NoxWorkSession(
            id: sessionId,
            startedAt: session.startedAt,
            endedAt: Date(),
            primaryApp: session.primaryApp,
            primaryBundleId: session.primaryBundleId,
            interruptionCount: 0,
            appSwitchCount: 1,
            confidence: 0.75,
            state: .ended
        )
        try await store.upsert(ended, endReason: .interruptedByRestart)
    }
}

struct NoxMemoryStoreRangeTests {

    private func isolatedDatabaseURL() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("nox-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("timeline.db")
    }

    @Test func spansOverlappingPeriodAreReturned() async throws {
        let dbURL = try isolatedDatabaseURL()
        let store = NoxMemoryStore(databaseURL: dbURL)
        try await store.open()

        let periodStart = Date(timeIntervalSince1970: 10_000)
        let periodEnd = periodStart.addingTimeInterval(3_600)
        let span = NoxActivitySpan(
            id: "cross-boundary",
            startedAt: periodStart.addingTimeInterval(-600),
            endedAt: periodStart.addingTimeInterval(900),
            appName: "Codex",
            bundleId: "com.openai.codex",
            windowTitle: "Nox",
            contextLabel: "Focused in Codex",
            category: .development,
            interruptions: 0,
            focusScore: 0.7,
            metadataJson: nil
        )

        try await store.upsertSpan(span)

        let result = try await store.spans(from: periodStart, to: periodEnd)
        #expect(result.map(\.id).contains("cross-boundary"))
    }
}

struct NoxRestartRecoveryTests {

    private func isolatedDatabaseURL() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("nox-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("timeline.db")
    }

    @Test func longGapInterruptsActiveSession() async throws {
        let dbURL = try isolatedDatabaseURL()
        let memoryStore = NoxMemoryStore(databaseURL: dbURL)
        try await memoryStore.open()
        let sessionStore = NoxSessionStore(databaseURL: dbURL)
        try await sessionStore.open()

        try await sessionStore.upsert(
            NoxWorkSession(
                id: "recovery-session",
                startedAt: Date().addingTimeInterval(-1200),
                endedAt: nil,
                primaryApp: "Safari",
                primaryBundleId: "com.apple.Safari",
                interruptionCount: 0,
                appSwitchCount: 0,
                confidence: 0.7,
                state: .active
            )
        )

        let ambient = NoxAmbientState(
            lastPresence: nil,
            lastActiveAppName: "Safari",
            lastActiveBundleId: "com.apple.Safari",
            lastActiveWindowTitle: nil,
            observationStartedAt: nil,
            lastShutdownAt: Date().addingTimeInterval(-3600),
            recentBundleIds: ["com.apple.Safari"],
            continuityNote: nil,
            lastMorningSummaryAt: nil,
            lastResurfacingShownAt: nil
        )

        let result = try await NoxRestartRecovery.recover(
            sessionStore: sessionStore,
            memoryStore: memoryStore,
            ambient: ambient,
            currentBundleId: "com.apple.dt.Xcode"
        )

        #expect(result.resumedSession == nil)
        #expect(result.interruptedSessionCount == 1)
        #expect(try await sessionStore.activeSession() == nil)
    }
}
