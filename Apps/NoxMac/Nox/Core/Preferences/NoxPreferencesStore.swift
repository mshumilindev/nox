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

actor NoxPreferencesStore {
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
            CREATE TABLE IF NOT EXISTS ambient_state (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                updated_at REAL NOT NULL
            );
            """)
    }

    func loadPreferences() throws -> NoxAmbientPreferences {
        guard let json = try get(key: "preferences"),
              let data = json.data(using: .utf8),
              let prefs = try? decoder.decode(NoxAmbientPreferences.self, from: data) else {
            return .default
        }
        return prefs
    }

    func savePreferences(_ preferences: NoxAmbientPreferences) throws {
        let data = try encoder.encode(preferences)
        guard let json = String(data: data, encoding: .utf8) else { return }
        try set(key: "preferences", value: json)
    }

    private func get(key: String) throws -> String? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT value FROM ambient_state WHERE key = ? LIMIT 1;", -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.execFailed
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, key, -1, noxSQLiteTransient)
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        return String(cString: sqlite3_column_text(statement, 0))
    }

    private func set(key: String, value: String) throws {
        try execute(
            sql: """
            INSERT INTO ambient_state (key, value, updated_at)
            VALUES (?, ?, ?)
            ON CONFLICT(key) DO UPDATE SET value=excluded.value, updated_at=excluded.updated_at;
            """,
            bindings: [.text(key), .text(value), .double(Date().timeIntervalSince1970)]
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
