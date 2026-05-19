import Foundation
import SQLite3

enum NoxWorkSessionEndReason: String, Codable, Sendable {
    case completed
    case interruptedByRestart
    case idle
}

actor NoxSessionStore {
    private var db: OpaquePointer?
    private let databaseURL: URL

    init(databaseURL: URL = NoxPersistencePaths.databaseURL) {
        self.databaseURL = databaseURL
    }

    func open() throws {
        if db != nil { return }
        NoxPersistencePaths.ensureDirectory(at: databaseURL.deletingLastPathComponent())
        if sqlite3_open(databaseURL.path, &db) != SQLITE_OK {
            throw NoxMemoryStoreError.openFailed
        }
        try execute(sql: """
            CREATE TABLE IF NOT EXISTS work_sessions (
                id TEXT PRIMARY KEY,
                started_at REAL NOT NULL,
                ended_at REAL,
                primary_app TEXT NOT NULL,
                primary_bundle_id TEXT NOT NULL,
                interruption_count INTEGER NOT NULL DEFAULT 0,
                app_switch_count INTEGER NOT NULL DEFAULT 0,
                confidence REAL NOT NULL,
                state TEXT NOT NULL,
                end_reason TEXT
            );
            CREATE INDEX IF NOT EXISTS idx_sessions_started ON work_sessions(started_at DESC);
            CREATE INDEX IF NOT EXISTS idx_sessions_active ON work_sessions(state);
            """)
    }

    func upsert(_ session: NoxWorkSession, endReason: NoxWorkSessionEndReason? = nil) throws {
        try execute(
            sql: """
            INSERT INTO work_sessions
            (id, started_at, ended_at, primary_app, primary_bundle_id, interruption_count, app_switch_count, confidence, state, end_reason)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                ended_at=excluded.ended_at,
                interruption_count=excluded.interruption_count,
                app_switch_count=excluded.app_switch_count,
                confidence=excluded.confidence,
                state=excluded.state,
                end_reason=excluded.end_reason;
            """,
            bindings: [
                .text(session.id),
                .double(session.startedAt.timeIntervalSince1970),
                .doubleOptional(session.endedAt?.timeIntervalSince1970),
                .text(session.primaryApp),
                .text(session.primaryBundleId),
                .int(session.interruptionCount),
                .int(session.appSwitchCount),
                .double(session.confidence),
                .text(session.state.rawValue),
                .textOptional(endReason?.rawValue)
            ]
        )
    }

    func activeSession() throws -> NoxWorkSession? {
        let rows = try fetch(sql: """
            SELECT id, started_at, ended_at, primary_app, primary_bundle_id, interruption_count, app_switch_count, confidence, state
            FROM work_sessions
            WHERE state = 'active' AND ended_at IS NULL
            ORDER BY started_at DESC
            LIMIT 1;
            """)
        return rows.first
    }

    func recentSessions(limit: Int = 10) throws -> [NoxWorkSession] {
        try fetch(sql: """
            SELECT id, started_at, ended_at, primary_app, primary_bundle_id, interruption_count, app_switch_count, confidence, state
            FROM work_sessions
            ORDER BY started_at DESC
            LIMIT ?;
            """, bindings: [.int(limit)])
    }

    func closeActiveSessions(at date: Date, reason: NoxWorkSessionEndReason) throws {
        try execute(
            sql: """
            UPDATE work_sessions
            SET ended_at = ?, state = 'ended', end_reason = ?
            WHERE state = 'active' AND ended_at IS NULL;
            """,
            bindings: [.double(date.timeIntervalSince1970), .text(reason.rawValue)]
        )
    }

    private func fetch(sql: String, bindings: [Binding] = []) throws -> [NoxWorkSession] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.execFailed
        }
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)
        var results: [NoxWorkSession] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = String(cString: sqlite3_column_text(statement, 0))
            let started = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
            let ended = sqlite3_column_type(statement, 2) == SQLITE_NULL
                ? nil
                : Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
            let app = String(cString: sqlite3_column_text(statement, 3))
            let bundle = String(cString: sqlite3_column_text(statement, 4))
            let interruptions = Int(sqlite3_column_int(statement, 5))
            let switches = Int(sqlite3_column_int(statement, 6))
            let confidence = sqlite3_column_double(statement, 7)
            let stateRaw = String(cString: sqlite3_column_text(statement, 8))
            results.append(
                NoxWorkSession(
                    id: id,
                    startedAt: started,
                    endedAt: ended,
                    primaryApp: app,
                    primaryBundleId: bundle,
                    interruptionCount: interruptions,
                    appSwitchCount: switches,
                    confidence: confidence,
                    state: NoxWorkSessionState(rawValue: stateRaw) ?? .ended
                )
            )
        }
        return results
    }

    private enum Binding {
        case text(String)
        case textOptional(String?)
        case double(Double)
        case doubleOptional(Double?)
        case int(Int)
    }

    private func bind(_ bindings: [Binding], to statement: OpaquePointer?) throws {
        for (index, binding) in bindings.enumerated() {
            let i = Int32(index + 1)
            switch binding {
            case .text(let value):
                sqlite3_bind_text(statement, i, value, -1, noxSQLiteTransient)
            case .textOptional(let value):
                if let value {
                    sqlite3_bind_text(statement, i, value, -1, noxSQLiteTransient)
                } else {
                    sqlite3_bind_null(statement, i)
                }
            case .double(let value):
                sqlite3_bind_double(statement, i, value)
            case .doubleOptional(let value):
                if let value {
                    sqlite3_bind_double(statement, i, value)
                } else {
                    sqlite3_bind_null(statement, i)
                }
            case .int(let value):
                sqlite3_bind_int(statement, i, Int32(value))
            }
        }
    }

    private func execute(sql: String, bindings: [Binding] = []) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.execFailed
        }
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw NoxMemoryStoreError.execFailed
        }
    }
}
