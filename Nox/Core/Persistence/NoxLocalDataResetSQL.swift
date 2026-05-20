import Foundation
import SQLite3

enum NoxLocalDataResetSQL {
    private static let bundleId = "dev.nox.Nox"

    static func purgeContinuityObservations(at databaseURL: URL) throws -> NoxContinuityResetReport {
        var db: OpaquePointer?
        guard sqlite3_open(databaseURL.path, &db) == SQLITE_OK else {
            throw NoxMemoryStoreError.openFailed
        }
        defer { sqlite3_close(db) }

        let timeline = try runDelete(db, sql: "DELETE FROM timeline_events;")
        let activity = try runDelete(db, sql: "DELETE FROM activity_spans;")
        let semantic = try runDelete(db, sql: "DELETE FROM semantic_spans;")
        let focus = try runDelete(db, sql: "DELETE FROM focus_blocks;")
        let interruptions = try runDelete(db, sql: "DELETE FROM interruptions;")
        let sessions = try runDelete(db, sql: "DELETE FROM work_sessions;")
        let rollups = try runDelete(db, sql: "DELETE FROM memory_rollups;")
        let threads = try runDelete(db, sql: "DELETE FROM continuity_threads;")
        let typed = try runDelete(db, sql: "DELETE FROM typed_memories;")
        let reflections = try runDelete(db, sql: "DELETE FROM reflections;")
        let behavioral = try runDelete(db, sql: "DELETE FROM behavioral_intelligence;")
        let connector = try runDelete(db, sql: "DELETE FROM connector_signals;")
        sqlite3_exec(db, "VACUUM;", nil, nil, nil)

        return NoxContinuityResetReport(
            timelineEvents: timeline,
            activitySpans: activity,
            semanticSpans: semantic,
            focusBlocks: focus,
            interruptions: interruptions,
            workSessions: sessions,
            memoryRollups: rollups,
            continuityThreads: threads,
            typedMemories: typed,
            reflections: reflections,
            behavioralSignals: behavioral,
            connectorSignals: connector
        )
    }

    static func purgeNoxSelf(at databaseURL: URL) throws -> NoxPurgeReport {
        var db: OpaquePointer?
        guard sqlite3_open(databaseURL.path, &db) == SQLITE_OK else {
            throw NoxMemoryStoreError.openFailed
        }
        defer { sqlite3_close(db) }

        let timeline = try runDelete(
            db,
            sql: """
            DELETE FROM timeline_events
            WHERE bundle_id = ? OR lower(app_name) = 'nox';
            """,
            bindings: [bundleId]
        )
        let spans = try runDelete(
            db,
            sql: """
            DELETE FROM activity_spans
            WHERE bundle_id = ? OR lower(app_name) = 'nox';
            """,
            bindings: [bundleId]
        )
        let sessions = try runDelete(
            db,
            sql: """
            DELETE FROM work_sessions
            WHERE primary_bundle_id = ? OR lower(primary_app) = 'nox';
            """,
            bindings: [bundleId]
        )
        let semantic = try runDelete(
            db,
            sql: """
            DELETE FROM semantic_spans
            WHERE app_names LIKE '%Nox%' OR app_names LIKE '%nox%';
            """
        )

        _ = try? runDelete(db, sql: """
            DELETE FROM interruptions
            WHERE from_bundle_id = ? OR to_bundle_id = ?
               OR lower(from_app) = 'nox' OR lower(to_app) = 'nox';
            """, bindings: [bundleId, bundleId])

        _ = try? runDelete(db, sql: """
            DELETE FROM focus_blocks
            WHERE primary_bundle_id = ? OR lower(primary_app) = 'nox';
            """, bindings: [bundleId])

        _ = try? runDelete(db, sql: """
            DELETE FROM typed_memories
            WHERE title LIKE '%Nox%' OR summary LIKE '%Nox%';
            """)

        try resetAmbientState(db)
        sqlite3_exec(db, "VACUUM;", nil, nil, nil)

        return NoxPurgeReport(
            timelineEvents: timeline,
            activitySpans: spans,
            workSessions: sessions,
            semanticSpans: semantic
        )
    }

    private static func resetAmbientState(_ db: OpaquePointer?) throws {
        let empty = """
        {"lastPresence":null,"lastActiveAppName":null,"lastActiveBundleId":null,\
        "lastActiveWindowTitle":null,"observationStartedAt":null,"lastShutdownAt":null,\
        "recentBundleIds":[],"continuityNote":null}
        """
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(
            db,
            "DELETE FROM ambient_state; INSERT INTO ambient_state (key, value, updated_at) VALUES ('ambient', ?, ?);",
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            return
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, empty, -1, transient)
        sqlite3_bind_double(statement, 2, Date().timeIntervalSince1970)
        _ = sqlite3_step(statement)
    }

    private static func runDelete(
        _ db: OpaquePointer?,
        sql: String,
        bindings: [String] = []
    ) throws -> Int {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.execFailed
        }
        defer { sqlite3_finalize(statement) }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        for (index, value) in bindings.enumerated() {
            sqlite3_bind_text(statement, Int32(index + 1), value, -1, transient)
        }
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw NoxMemoryStoreError.execFailed
        }
        return Int(sqlite3_changes(db))
    }
}
