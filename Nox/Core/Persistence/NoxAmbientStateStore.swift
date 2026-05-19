import Foundation
import SQLite3

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

actor NoxAmbientStateStore {
    private var db: OpaquePointer?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func open() throws {
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

    func save(_ state: NoxAmbientState) throws {
        let data = try encoder.encode(state)
        guard let json = String(data: data, encoding: .utf8) else { return }
        try set(key: "ambient", value: json)
    }

    func load() throws -> NoxAmbientState {
        guard let json = try get(key: "ambient"),
              let data = json.data(using: .utf8) else {
            return .empty
        }
        return try decoder.decode(NoxAmbientState.self, from: data)
    }

    func saveSignalTracker(_ tracker: NoxPersistedSignalTracker) throws {
        let data = try encoder.encode(tracker)
        guard let json = String(data: data, encoding: .utf8) else { return }
        try set(key: "signal_tracker", value: json)
    }

    func loadSignalTracker() throws -> NoxPersistedSignalTracker? {
        guard let json = try get(key: "signal_tracker"),
              let data = json.data(using: .utf8) else {
            return nil
        }
        return try decoder.decode(NoxPersistedSignalTracker.self, from: data)
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

    private func get(key: String) throws -> String? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT value FROM ambient_state WHERE key = ? LIMIT 1;", -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.execFailed
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, key, -1, sqliteTransient)
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        return String(cString: sqlite3_column_text(statement, 0))
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
            let i = Int32(index + 1)
            switch binding {
            case .text(let value):
                sqlite3_bind_text(statement, i, value, -1, sqliteTransient)
            case .double(let value):
                sqlite3_bind_double(statement, i, value)
            }
        }
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw NoxMemoryStoreError.execFailed
        }
    }
}
