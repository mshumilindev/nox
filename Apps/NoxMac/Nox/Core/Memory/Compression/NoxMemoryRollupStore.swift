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

actor NoxMemoryRollupStore {
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
        try executeScript("""
            CREATE TABLE IF NOT EXISTS memory_rollups (
                id TEXT PRIMARY KEY,
                level TEXT NOT NULL,
                period_start REAL NOT NULL,
                period_end REAL NOT NULL,
                generated_at REAL NOT NULL,
                version INTEGER NOT NULL DEFAULT 1,
                facts_json TEXT NOT NULL,
                summary_text TEXT NOT NULL,
                source_counts_json TEXT
            );
            CREATE UNIQUE INDEX IF NOT EXISTS idx_rollup_level_period
                ON memory_rollups(level, period_start);
            CREATE INDEX IF NOT EXISTS idx_rollup_generated ON memory_rollups(generated_at DESC);
            """)
    }

    func upsert(_ snapshot: NoxMemoryRollupSnapshot) throws {
        let factsData = try encoder.encode(snapshot.facts)
        guard let factsJson = String(data: factsData, encoding: .utf8) else {
            throw NoxMemoryStoreError.execFailed
        }
        try execute(
            sql: """
            INSERT INTO memory_rollups
            (id, level, period_start, period_end, generated_at, version, facts_json, summary_text, source_counts_json)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                period_end=excluded.period_end,
                generated_at=excluded.generated_at,
                version=excluded.version,
                facts_json=excluded.facts_json,
                summary_text=excluded.summary_text,
                source_counts_json=excluded.source_counts_json;
            """,
            bindings: [
                .text(snapshot.id),
                .text(snapshot.level.rawValue),
                .double(snapshot.periodStart.timeIntervalSince1970),
                .double(snapshot.periodEnd.timeIntervalSince1970),
                .double(snapshot.generatedAt.timeIntervalSince1970),
                .int(snapshot.version),
                .text(factsJson),
                .text(snapshot.summaryText),
                .textOptional(snapshot.sourceCountsJson)
            ]
        )
    }

    func exists(level: NoxMemoryCompressionLevel, periodStart: Date) throws -> Bool {
        let rows = try fetchIDs(sql: """
            SELECT id FROM memory_rollups
            WHERE level = ? AND period_start = ?
            LIMIT 1;
            """, bindings: [.text(level.rawValue), .double(periodStart.timeIntervalSince1970)])
        return !rows.isEmpty
    }

    func rollup(level: NoxMemoryCompressionLevel, periodStart: Date) throws -> NoxMemoryRollupSnapshot? {
        try fetch(sql: """
            SELECT id, level, period_start, period_end, generated_at, version, facts_json, summary_text, source_counts_json
            FROM memory_rollups
            WHERE level = ? AND period_start = ?
            LIMIT 1;
            """, bindings: [.text(level.rawValue), .double(periodStart.timeIntervalSince1970)]).first
    }

    func rollups(
        level: NoxMemoryCompressionLevel,
        from start: Date,
        to end: Date
    ) throws -> [NoxMemoryRollupSnapshot] {
        try fetch(sql: """
            SELECT id, level, period_start, period_end, generated_at, version, facts_json, summary_text, source_counts_json
            FROM memory_rollups
            WHERE level = ? AND period_start >= ? AND period_start < ?
            ORDER BY period_start ASC;
            """, bindings: [
            .text(level.rawValue),
            .double(start.timeIntervalSince1970),
            .double(end.timeIntervalSince1970)
        ])
    }

    func deleteRollups(level: NoxMemoryCompressionLevel, before: Date) throws -> Int {
        try delete(sql: """
            DELETE FROM memory_rollups
            WHERE level = ? AND period_start < ?;
            """, bindings: [.text(level.rawValue), .double(before.timeIntervalSince1970)])
    }

    // MARK: - SQLite helpers

    private enum Binding {
        case text(String)
        case textOptional(String?)
        case double(Double)
        case int(Int)
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

    private func executeScript(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            sqlite3_free(errorMessage)
            throw NoxMemoryStoreError.execFailed
        }
    }

    private func delete(sql: String, bindings: [Binding]) throws -> Int {
        try execute(sql: sql, bindings: bindings)
        return Int(sqlite3_changes(db))
    }

    private func fetchIDs(sql: String, bindings: [Binding]) throws -> [String] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.queryFailed
        }
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)
        var ids: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            ids.append(String(cString: sqlite3_column_text(statement, 0)))
        }
        return ids
    }

    private func fetch(sql: String, bindings: [Binding]) throws -> [NoxMemoryRollupSnapshot] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.queryFailed
        }
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)

        var items: [NoxMemoryRollupSnapshot] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = String(cString: sqlite3_column_text(statement, 0))
            let levelRaw = String(cString: sqlite3_column_text(statement, 1))
            let normalized = levelRaw == "decade" ? "era" : levelRaw
            let level = NoxMemoryCompressionLevel(rawValue: normalized) ?? .daily
            let periodStart = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
            let periodEnd = Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
            let generatedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))
            let version = Int(sqlite3_column_int(statement, 5))
            let factsJson = String(cString: sqlite3_column_text(statement, 6))
            let summary = String(cString: sqlite3_column_text(statement, 7))
            let sourceCounts = columnOptionalString(statement, 8)
            guard let factsData = factsJson.data(using: .utf8) else { continue }
            let facts = try decoder.decode(NoxRollupFacts.self, from: factsData)
            items.append(
                NoxMemoryRollupSnapshot(
                    id: id,
                    level: level,
                    periodStart: periodStart,
                    periodEnd: periodEnd,
                    generatedAt: generatedAt,
                    version: version,
                    facts: facts,
                    summaryText: summary,
                    sourceCountsJson: sourceCounts
                )
            )
        }
        return items
    }

    private func bind(_ bindings: [Binding], to statement: OpaquePointer?) throws {
        for (index, binding) in bindings.enumerated() {
            let position = Int32(index + 1)
            switch binding {
            case .text(let value):
                sqlite3_bind_text(statement, position, value, -1, noxSQLiteTransient)
            case .textOptional(let value):
                if let value {
                    sqlite3_bind_text(statement, position, value, -1, noxSQLiteTransient)
                } else {
                    sqlite3_bind_null(statement, position)
                }
            case .double(let value):
                sqlite3_bind_double(statement, position, value)
            case .int(let value):
                sqlite3_bind_int(statement, position, Int32(value))
            }
        }
    }

    private func columnOptionalString(_ statement: OpaquePointer?, _ index: Int32) -> String? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        return String(cString: sqlite3_column_text(statement, index))
    }
}
