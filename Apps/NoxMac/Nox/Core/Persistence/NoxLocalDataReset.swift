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

/// Purges persisted local data — full wipe or Nox self-exclusion cleanup only.
enum NoxLocalDataReset {
    static let sandboxDatabaseURL = NoxPersistencePaths.databaseURL

    /// Removes every row tied to Nox (bundle `dev.nox.Nox` / app name "Nox") from the local store.
    @discardableResult
    static func purgeNoxSelfFromStore(at databaseURL: URL = NoxPersistencePaths.databaseURL) throws -> NoxPurgeReport {
        guard FileManager.default.fileExists(atPath: databaseURL.path) else {
            return .empty
        }
        return try NoxLocalDataResetSQL.purgeNoxSelf(at: databaseURL)
    }

    /// Clears derived continuity observations while preserving ambient preferences/state.
    @discardableResult
    static func purgeContinuityObservations(at databaseURL: URL = NoxPersistencePaths.databaseURL) throws -> NoxContinuityResetReport {
        guard FileManager.default.fileExists(atPath: databaseURL.path) else {
            return .empty
        }
        return try NoxLocalDataResetSQL.purgeContinuityObservations(at: databaseURL)
    }

    /// Deletes the entire local database file and support folder contents.
    static func wipeAllLocalData() throws {
        let folder = NoxPersistencePaths.applicationSupportDirectory
        let db = NoxPersistencePaths.databaseURL
        if FileManager.default.fileExists(atPath: db.path) {
            try FileManager.default.removeItem(at: db)
        }
        if let contents = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
            for item in contents where item != db {
                try? FileManager.default.removeItem(at: item)
            }
        }
        NoxPersistencePaths.ensureDirectory()
    }
}

struct NoxPurgeReport: Equatable, Sendable {
    let timelineEvents: Int
    let activitySpans: Int
    let workSessions: Int
    let semanticSpans: Int

    static let empty = NoxPurgeReport(timelineEvents: 0, activitySpans: 0, workSessions: 0, semanticSpans: 0)
}

struct NoxContinuityResetReport: Equatable, Sendable {
    let timelineEvents: Int
    let activitySpans: Int
    let semanticSpans: Int
    let focusBlocks: Int
    let interruptions: Int
    let workSessions: Int
    let memoryRollups: Int
    let continuityThreads: Int
    let typedMemories: Int
    let reflections: Int
    let behavioralSignals: Int
    let connectorSignals: Int

    static let empty = NoxContinuityResetReport(
        timelineEvents: 0,
        activitySpans: 0,
        semanticSpans: 0,
        focusBlocks: 0,
        interruptions: 0,
        workSessions: 0,
        memoryRollups: 0,
        continuityThreads: 0,
        typedMemories: 0,
        reflections: 0,
        behavioralSignals: 0,
        connectorSignals: 0
    )
}
