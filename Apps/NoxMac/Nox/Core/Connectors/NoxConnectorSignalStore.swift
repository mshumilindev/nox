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

actor NoxConnectorSignalStore {
    private var db: OpaquePointer?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func open() throws {
        if db != nil { return }
        NoxPersistencePaths.ensureDirectory()
        if sqlite3_open(NoxPersistencePaths.databaseURL.path, &db) != SQLITE_OK {
            throw NoxMemoryStoreError.openFailed
        }
        try execute(sql: """
            CREATE TABLE IF NOT EXISTS connector_signals (
                id TEXT PRIMARY KEY,
                kind TEXT NOT NULL,
                payload TEXT NOT NULL,
                observed_at REAL NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_connector_signals_observed
                ON connector_signals(observed_at DESC);
            """)
    }

    func recentCadencePatterns(limit: Int = 12) throws -> [NoxCadencePattern] {
        let rows = try fetchRecent(kind: "cadence", limit: limit)
        return rows.compactMap { row in
            guard let data = row.data(using: .utf8),
                  let pattern = try? decoder.decode(NoxCadencePattern.self, from: data) else { return nil }
            return pattern
        }
    }

    func appendCadencePatterns(_ patterns: [NoxCadencePattern]) throws {
        for pattern in patterns where pattern.confidence >= 0.62 {
            let data = try encoder.encode(pattern)
            guard let json = String(data: data, encoding: .utf8) else { continue }
            try upsert(id: pattern.id, kind: "cadence", payload: json, observedAt: Date())
        }
    }

    func clearConnectorDerived() throws {
        try execute(sql: "DELETE FROM connector_signals;")
    }

    private func fetchRecent(kind: String, limit: Int) throws -> [String] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(
            db,
            "SELECT payload FROM connector_signals WHERE kind = ? ORDER BY observed_at DESC LIMIT ?;",
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw NoxMemoryStoreError.execFailed
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, kind, -1, noxSQLiteTransient)
        sqlite3_bind_int(statement, 2, Int32(limit))

        var payloads: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            payloads.append(String(cString: sqlite3_column_text(statement, 0)))
        }
        return payloads
    }

    private func upsert(id: String, kind: String, payload: String, observedAt: Date) throws {
        try execute(
            sql: """
            INSERT INTO connector_signals (id, kind, payload, observed_at)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET payload=excluded.payload, observed_at=excluded.observed_at;
            """,
            bindings: [
                .text(id),
                .text(kind),
                .text(payload),
                .double(observedAt.timeIntervalSince1970)
            ]
        )
    }

    private enum Binding {
        case text(String)
        case double(Double)
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
            }
        }
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw NoxMemoryStoreError.execFailed
        }
    }
}
