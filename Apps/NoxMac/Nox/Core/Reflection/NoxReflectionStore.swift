import Foundation
import SQLite3
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

actor NoxReflectionStore {
    private var db: OpaquePointer?
    private let databaseURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

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
            CREATE TABLE IF NOT EXISTS reflections (
                id TEXT PRIMARY KEY,
                text TEXT NOT NULL,
                confidence REAL NOT NULL,
                signals_json TEXT NOT NULL,
                created_at REAL NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_reflections_created ON reflections(created_at DESC);
            """)
        try? execute(sql: "ALTER TABLE reflections ADD COLUMN detail_line TEXT;")
        try? pruneDuplicateTexts()
    }

    func pruneDuplicateTexts() throws {
        try execute(sql: """
            DELETE FROM reflections
            WHERE rowid NOT IN (
                SELECT MIN(rowid)
                FROM reflections
                GROUP BY lower(trim(text))
            );
            """)
    }

    func upsert(_ candidate: NoxReflectionCandidate) throws {
        let signalsData = try encoder.encode(candidate.sourceSignals)
        guard let signalsJson = String(data: signalsData, encoding: .utf8) else {
            throw NoxMemoryStoreError.execFailed
        }
        try execute(
            sql: """
            INSERT INTO reflections (id, text, confidence, signals_json, created_at, detail_line)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                text=excluded.text,
                confidence=excluded.confidence,
                signals_json=excluded.signals_json,
                created_at=excluded.created_at,
                detail_line=excluded.detail_line;
            """,
            bindings: [
                .text(candidate.id),
                .text(candidate.text),
                .double(candidate.confidence),
                .text(signalsJson),
                .double(candidate.createdAt.timeIntervalSince1970),
                .text(candidate.detailLine)
            ]
        )
    }

    func recent(limit: Int = 6) throws -> [NoxReflectionCandidate] {
        var statement: OpaquePointer?
        let sql = """
            SELECT id, text, confidence, signals_json, created_at, detail_line
            FROM reflections ORDER BY created_at DESC LIMIT ?;
            """
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.execFailed
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_int(statement, 1, Int32(limit))

        var results: [NoxReflectionCandidate] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = String(cString: sqlite3_column_text(statement, 0))
            let text = String(cString: sqlite3_column_text(statement, 1))
            let confidence = sqlite3_column_double(statement, 2)
            let signalsJson = String(cString: sqlite3_column_text(statement, 3))
            let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))
            let detailLine: String
            if sqlite3_column_type(statement, 5) != SQLITE_NULL {
                detailLine = String(cString: sqlite3_column_text(statement, 5))
            } else {
                detailLine = NoxReflectionPresenter.defaultDetailLine
            }
            let signals = (try? decoder.decode([String].self, from: Data(signalsJson.utf8))) ?? []
            results.append(NoxReflectionCandidate(
                id: id,
                text: text,
                detailLine: detailLine,
                confidence: confidence,
                createdAt: createdAt,
                sourceSignals: signals
            ))
        }
        return results
    }

    func lastCreatedAt() throws -> Date? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT created_at FROM reflections ORDER BY created_at DESC LIMIT 1;", -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.execFailed
        }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        return Date(timeIntervalSince1970: sqlite3_column_double(statement, 0))
    }

    private enum Binding {
        case text(String)
        case double(Double)
        case int(Int)
    }

    private func execute(sql: String, bindings: [Binding] = []) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.execFailed
        }
        defer { sqlite3_finalize(statement) }
        for (index, binding) in bindings.enumerated() {
            let position = Int32(index + 1)
            switch binding {
            case .text(let value):
                sqlite3_bind_text(statement, position, value, -1, noxSQLiteTransient)
            case .double(let value):
                sqlite3_bind_double(statement, position, value)
            case .int(let value):
                sqlite3_bind_int(statement, position, Int32(value))
            }
        }
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw NoxMemoryStoreError.execFailed
        }
    }
}
