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

actor NoxTypedMemoryStore {
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
            CREATE TABLE IF NOT EXISTS typed_memories (
                id TEXT PRIMARY KEY,
                kind TEXT NOT NULL,
                title TEXT NOT NULL,
                summary TEXT NOT NULL,
                period_start REAL,
                period_end REAL,
                confidence REAL NOT NULL,
                signals_json TEXT NOT NULL,
                metadata_json TEXT,
                sensitivity_level TEXT NOT NULL,
                source_horizon TEXT,
                created_at REAL NOT NULL,
                updated_at REAL NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_typed_kind ON typed_memories(kind);
            CREATE INDEX IF NOT EXISTS idx_typed_created ON typed_memories(created_at DESC);
            """)
    }

    func upsert(_ entity: NoxTypedMemoryEntity) throws {
        let signalsData = try encoder.encode(entity.supportingSignals)
        guard let signalsJson = String(data: signalsData, encoding: .utf8) else {
            throw NoxMemoryStoreError.execFailed
        }
        let metadataData = try encoder.encode(entity.metadata)
        let metadataJson = String(data: metadataData, encoding: .utf8)

        try execute(
            sql: """
            INSERT INTO typed_memories
            (id, kind, title, summary, period_start, period_end, confidence, signals_json,
             metadata_json, sensitivity_level, source_horizon, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                title=excluded.title,
                summary=excluded.summary,
                confidence=excluded.confidence,
                signals_json=excluded.signals_json,
                metadata_json=excluded.metadata_json,
                updated_at=excluded.updated_at;
            """,
            bindings: [
                .text(entity.id),
                .text(entity.kind.rawValue),
                .text(entity.title),
                .text(entity.summary),
                .doubleOptional(entity.periodStart?.timeIntervalSince1970),
                .doubleOptional(entity.periodEnd?.timeIntervalSince1970),
                .double(entity.confidence),
                .text(signalsJson),
                .textOptional(metadataJson),
                .text(entity.sensitivityLevel.rawValue),
                .textOptional(entity.sourceHorizon?.rawValue),
                .double(entity.createdAt.timeIntervalSince1970),
                .double(entity.updatedAt.timeIntervalSince1970)
            ]
        )
    }

    func recent(limit: Int = 50) throws -> [NoxTypedMemoryEntity] {
        try fetch(sql: """
            SELECT id, kind, title, summary, period_start, period_end, confidence, signals_json,
                   metadata_json, sensitivity_level, source_horizon, created_at, updated_at
            FROM typed_memories
            ORDER BY updated_at DESC
            LIMIT ?;
            """, bindings: [.int(limit)])
    }

    // MARK: - SQLite

    private enum Binding {
        case text(String)
        case textOptional(String?)
        case double(Double)
        case doubleOptional(Double?)
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

    private func fetch(sql: String, bindings: [Binding]) throws -> [NoxTypedMemoryEntity] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.queryFailed
        }
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)

        var items: [NoxTypedMemoryEntity] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = String(cString: sqlite3_column_text(statement, 0))
            let kind = NoxTypedMemoryKind(rawValue: String(cString: sqlite3_column_text(statement, 1))) ?? .longTermContext
            let title = String(cString: sqlite3_column_text(statement, 2))
            let summary = String(cString: sqlite3_column_text(statement, 3))
            let periodStart = columnOptionalDouble(statement, 4).map { Date(timeIntervalSince1970: $0) }
            let periodEnd = columnOptionalDouble(statement, 5).map { Date(timeIntervalSince1970: $0) }
            let confidence = sqlite3_column_double(statement, 6)
            let signalsJson = String(cString: sqlite3_column_text(statement, 7))
            let metadataJson = columnOptionalString(statement, 8)
            let sensitivity = NoxSensitivityLevel(rawValue: String(cString: sqlite3_column_text(statement, 9))) ?? .normal
            let horizonRaw = columnOptionalString(statement, 10)
            let horizon = horizonRaw.flatMap { NoxMemoryCompressionLevel(rawValue: $0 == "decade" ? "era" : $0) }
            let created = Date(timeIntervalSince1970: sqlite3_column_double(statement, 11))
            let updated = Date(timeIntervalSince1970: sqlite3_column_double(statement, 12))

            guard let signalsData = signalsJson.data(using: .utf8) else { continue }
            let signals = (try? decoder.decode([NoxExplainableSignal].self, from: signalsData)) ?? []
            let metadata: [String: String]
            if let metadataJson, let data = metadataJson.data(using: .utf8) {
                metadata = (try? decoder.decode([String: String].self, from: data)) ?? [:]
            } else {
                metadata = [:]
            }

            items.append(
                NoxTypedMemoryEntity(
                    id: id,
                    kind: kind,
                    title: title,
                    summary: summary,
                    periodStart: periodStart,
                    periodEnd: periodEnd,
                    confidence: confidence,
                    supportingSignals: signals,
                    metadata: metadata,
                    sensitivityLevel: sensitivity,
                    sourceHorizon: horizon,
                    createdAt: created,
                    updatedAt: updated
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
            case .doubleOptional(let value):
                if let value {
                    sqlite3_bind_double(statement, position, value)
                } else {
                    sqlite3_bind_null(statement, position)
                }
            case .int(let value):
                sqlite3_bind_int(statement, position, Int32(value))
            }
        }
    }

    private func columnOptionalString(_ statement: OpaquePointer?, _ index: Int32) -> String? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        return String(cString: sqlite3_column_text(statement, index))
    }

    private func columnOptionalDouble(_ statement: OpaquePointer?, _ index: Int32) -> Double? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        return sqlite3_column_double(statement, index)
    }
}
