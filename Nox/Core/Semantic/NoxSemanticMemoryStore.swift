import Foundation
import SQLite3

actor NoxSemanticMemoryStore {
    private var db: OpaquePointer?
    private let dbURL: URL

    init(fileManager: FileManager = .default) {
        NoxPersistencePaths.ensureDirectory()
        dbURL = NoxPersistencePaths.databaseURL
    }

    func open() throws {
        if db != nil { return }
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            throw NoxMemoryStoreError.openFailed
        }
        try executeScript("""
            CREATE TABLE IF NOT EXISTS semantic_spans (
                id TEXT PRIMARY KEY,
                started_at REAL NOT NULL,
                ended_at REAL,
                title TEXT NOT NULL,
                subtitle TEXT NOT NULL,
                interaction_style TEXT NOT NULL,
                semantic_state TEXT NOT NULL,
                fusion_label TEXT NOT NULL,
                sensitivity_level TEXT NOT NULL,
                confidence REAL NOT NULL,
                app_names TEXT,
                reasons_json TEXT,
                metadata_json TEXT
            );
            CREATE INDEX IF NOT EXISTS idx_semantic_started ON semantic_spans(started_at DESC);
            """)
        try ensureColumn(table: "semantic_spans", name: "metadata_json", definition: "TEXT")
    }

    func upsert(_ span: NoxSemanticMemorySpan) throws {
        try execute(
            sql: """
            INSERT INTO semantic_spans
            (id, started_at, ended_at, title, subtitle, interaction_style, semantic_state,
             fusion_label, sensitivity_level, confidence, app_names, reasons_json, metadata_json)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                ended_at=excluded.ended_at,
                title=excluded.title,
                subtitle=excluded.subtitle,
                interaction_style=excluded.interaction_style,
                semantic_state=excluded.semantic_state,
                fusion_label=excluded.fusion_label,
                sensitivity_level=excluded.sensitivity_level,
                confidence=excluded.confidence,
                app_names=excluded.app_names,
                reasons_json=excluded.reasons_json,
                metadata_json=excluded.metadata_json;
            """,
            bindings: [
                .text(span.id),
                .double(span.startedAt.timeIntervalSince1970),
                .doubleOptional(span.endedAt?.timeIntervalSince1970),
                .text(span.title),
                .text(span.subtitle),
                .text(span.interactionStyle),
                .text(span.semanticState.rawValue),
                .text(span.fusionLabel.rawValue),
                .text(span.sensitivityLevel.rawValue),
                .double(span.confidence),
                .text(span.appNames.joined(separator: ", ")),
                .textOptional(span.reasonsJson),
                .textOptional(span.metadataJson)
            ]
        )
    }

    func delete(id: String) throws {
        try execute(
            sql: "DELETE FROM semantic_spans WHERE id = ?;",
            bindings: [.text(id)]
        )
    }

    @discardableResult
    func deleteAll() throws -> Int {
        try execute(sql: "DELETE FROM semantic_spans;")
        return Int(sqlite3_changes(db))
    }

    func searchSpans(from start: Date, to end: Date, query: String) throws -> [NoxSemanticMemorySpan] {
        let pattern = "%\(query.lowercased())%"
        return try fetchSpans(
            sql: """
            SELECT id, started_at, ended_at, title, subtitle, interaction_style, semantic_state,
                   fusion_label, sensitivity_level, confidence, app_names, reasons_json, metadata_json
            FROM semantic_spans
            WHERE started_at < ? AND (ended_at IS NULL OR ended_at >= ?)
            AND (
                lower(title) LIKE ? OR
                lower(subtitle) LIKE ? OR
                lower(interaction_style) LIKE ? OR
                lower(semantic_state) LIKE ? OR
                lower(app_names) LIKE ?
            )
            ORDER BY started_at DESC
            LIMIT 24;
            """,
            bindings: [
                .double(end.timeIntervalSince1970),
                .double(start.timeIntervalSince1970),
                .text(pattern),
                .text(pattern),
                .text(pattern),
                .text(pattern),
                .text(pattern)
            ]
        )
    }

    func spans(from start: Date, to end: Date) throws -> [NoxSemanticMemorySpan] {
        try fetchSpans(
            sql: """
            SELECT id, started_at, ended_at, title, subtitle, interaction_style, semantic_state,
                   fusion_label, sensitivity_level, confidence, app_names, reasons_json, metadata_json
            FROM semantic_spans
            WHERE started_at < ? AND (ended_at IS NULL OR ended_at >= ?)
            ORDER BY started_at DESC
            LIMIT 24;
            """,
            bindings: [.double(end.timeIntervalSince1970), .double(start.timeIntervalSince1970)]
        )
    }

    private enum Binding {
        case text(String)
        case textOptional(String?)
        case double(Double)
        case doubleOptional(Double?)
    }

    private func fetchSpans(sql: String, bindings: [Binding]) throws -> [NoxSemanticMemorySpan] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.execFailed
        }
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)
        var results: [NoxSemanticMemorySpan] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = String(cString: sqlite3_column_text(statement, 0))
            let started = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
            let ended = sqlite3_column_type(statement, 2) == SQLITE_NULL
                ? nil
                : Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
            let title = String(cString: sqlite3_column_text(statement, 3))
            let subtitle = String(cString: sqlite3_column_text(statement, 4))
            let style = String(cString: sqlite3_column_text(statement, 5))
            let state = NoxSemanticState(rawValue: String(cString: sqlite3_column_text(statement, 6))) ?? .unknown
            let fusion = NoxFusionLabel(rawValue: String(cString: sqlite3_column_text(statement, 7))) ?? .unknown
            let sensitivity = NoxSensitivityLevel(rawValue: String(cString: sqlite3_column_text(statement, 8))) ?? .normal
            let confidence = sqlite3_column_double(statement, 9)
            let apps = String(cString: sqlite3_column_text(statement, 10))
            let reasons = sqlite3_column_type(statement, 11) == SQLITE_NULL
                ? nil
                : String(cString: sqlite3_column_text(statement, 11))
            let metadata = sqlite3_column_type(statement, 12) == SQLITE_NULL
                ? nil
                : String(cString: sqlite3_column_text(statement, 12))
            results.append(
                NoxSemanticMemorySpan(
                    id: id,
                    startedAt: started,
                    endedAt: ended,
                    title: title,
                    subtitle: subtitle,
                    interactionStyle: style,
                    semanticState: state,
                    fusionLabel: fusion,
                    sensitivityLevel: sensitivity,
                    confidence: confidence,
                    appNames: apps.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                    reasonsJson: reasons,
                    metadataJson: metadata
                )
            )
        }
        return results
    }

    private func ensureColumn(table: String, name: String, definition: String) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, "PRAGMA table_info(\(table));", -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.execFailed
        }
        defer { sqlite3_finalize(statement) }

        var exists = false
        while sqlite3_step(statement) == SQLITE_ROW {
            let columnName = String(cString: sqlite3_column_text(statement, 1))
            if columnName == name {
                exists = true
                break
            }
        }

        if !exists {
            try execute(sql: "ALTER TABLE \(table) ADD COLUMN \(name) \(definition);")
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

    private func executeScript(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            sqlite3_free(errorMessage)
            throw NoxMemoryStoreError.execFailed
        }
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
            }
        }
    }
}
