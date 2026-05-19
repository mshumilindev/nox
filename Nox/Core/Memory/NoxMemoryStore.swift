import Foundation
import SQLite3

actor NoxMemoryStore {
    private var db: OpaquePointer?
    private let dbURL: URL

    init(databaseURL: URL = NoxPersistencePaths.databaseURL, fileManager: FileManager = .default) {
        _ = fileManager
        NoxPersistencePaths.ensureDirectory(at: databaseURL.deletingLastPathComponent())
        dbURL = databaseURL
    }

    func open() throws {
        if db != nil { return }
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            throw NoxMemoryStoreError.openFailed
        }
        try executeScript("""
            CREATE TABLE IF NOT EXISTS activity_spans (
                id TEXT PRIMARY KEY,
                started_at REAL NOT NULL,
                ended_at REAL,
                app_name TEXT NOT NULL,
                bundle_id TEXT NOT NULL,
                window_title TEXT,
                context_label TEXT,
                category TEXT NOT NULL,
                interruptions INTEGER NOT NULL DEFAULT 0,
                focus_score REAL NOT NULL DEFAULT 0,
                metadata_json TEXT
            );
            CREATE TABLE IF NOT EXISTS focus_blocks (
                id TEXT PRIMARY KEY,
                started_at REAL NOT NULL,
                ended_at REAL NOT NULL,
                primary_app TEXT NOT NULL,
                primary_bundle_id TEXT NOT NULL,
                duration_ms INTEGER NOT NULL,
                switch_count INTEGER NOT NULL,
                intensity REAL NOT NULL,
                continuity_score REAL NOT NULL,
                block_kind TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS interruptions (
                id TEXT PRIMARY KEY,
                timestamp REAL NOT NULL,
                from_app TEXT NOT NULL,
                from_bundle_id TEXT NOT NULL,
                to_app TEXT NOT NULL,
                to_bundle_id TEXT NOT NULL,
                duration_ms INTEGER NOT NULL,
                returned_back INTEGER NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_spans_started ON activity_spans(started_at DESC);
            CREATE INDEX IF NOT EXISTS idx_focus_started ON focus_blocks(started_at DESC);
            CREATE INDEX IF NOT EXISTS idx_interrupt_timestamp ON interruptions(timestamp DESC);
            """)
    }

    func upsertSpan(_ span: NoxActivitySpan) throws {
        try execute(
            sql: """
            INSERT INTO activity_spans
            (id, started_at, ended_at, app_name, bundle_id, window_title, context_label, category, interruptions, focus_score, metadata_json)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                ended_at=excluded.ended_at,
                window_title=excluded.window_title,
                context_label=excluded.context_label,
                interruptions=excluded.interruptions,
                focus_score=excluded.focus_score,
                metadata_json=excluded.metadata_json;
            """,
            bindings: [
                .text(span.id),
                .double(span.startedAt.timeIntervalSince1970),
                .doubleOptional(span.endedAt?.timeIntervalSince1970),
                .text(span.appName),
                .text(span.bundleId),
                .textOptional(span.windowTitle),
                .textOptional(span.contextLabel),
                .text(span.category.rawValue),
                .int(span.interruptions),
                .double(span.focusScore),
                .textOptional(span.metadataJson)
            ]
        )
    }

    func clearFocusBlocks(from start: Date, to end: Date) throws {
        try execute(
            sql: "DELETE FROM focus_blocks WHERE started_at >= ? AND started_at < ?;",
            bindings: [.double(start.timeIntervalSince1970), .double(end.timeIntervalSince1970)]
        )
    }

    func insertFocusBlock(_ block: NoxFocusBlock) throws {
        try execute(
            sql: """
            INSERT OR REPLACE INTO focus_blocks
            (id, started_at, ended_at, primary_app, primary_bundle_id, duration_ms, switch_count, intensity, continuity_score, block_kind)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            bindings: [
                .text(block.id),
                .double(block.startedAt.timeIntervalSince1970),
                .double(block.endedAt.timeIntervalSince1970),
                .text(block.primaryApp),
                .text(block.primaryBundleId),
                .int(block.durationMs),
                .int(block.switchCount),
                .double(block.intensity),
                .double(block.continuityScore),
                .text(block.kind.rawValue)
            ]
        )
    }

    func insertInterruption(_ item: NoxInterruption) throws {
        try execute(
            sql: """
            INSERT OR IGNORE INTO interruptions
            (id, timestamp, from_app, from_bundle_id, to_app, to_bundle_id, duration_ms, returned_back)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
            """,
            bindings: [
                .text(item.id),
                .double(item.timestamp.timeIntervalSince1970),
                .text(item.fromApp),
                .text(item.fromBundleId),
                .text(item.toApp),
                .text(item.toBundleId),
                .int(item.durationMs),
                .int(item.returnedBack ? 1 : 0)
            ]
        )
    }

    func openSpans() throws -> [NoxActivitySpan] {
        try fetchSpans(sql: """
            SELECT id, started_at, ended_at, app_name, bundle_id, window_title, context_label, category, interruptions, focus_score, metadata_json
            FROM activity_spans
            WHERE ended_at IS NULL
            ORDER BY started_at DESC;
            """)
    }

    /// Idempotent repair for rows stored before classifier covered AI tools.
    func repairLegacyUnknownCategories() throws -> Int {
        let legacy = try fetchSpans(sql: """
            SELECT id, started_at, ended_at, app_name, bundle_id, window_title, context_label, category, interruptions, focus_score, metadata_json
            FROM activity_spans
            WHERE category = 'unknown';
            """)
        var updated = 0
        for span in legacy {
            let resolved = NoxActivityCategory.resolving(
                stored: .unknown,
                appName: span.appName,
                bundleId: span.bundleId,
                windowTitle: span.windowTitle
            )
            guard resolved != .unknown else { continue }
            try upsertSpan(
                NoxActivitySpan(
                    id: span.id,
                    startedAt: span.startedAt,
                    endedAt: span.endedAt,
                    appName: span.appName,
                    bundleId: span.bundleId,
                    windowTitle: span.windowTitle,
                    contextLabel: span.contextLabel,
                    category: resolved,
                    interruptions: span.interruptions,
                    focusScore: span.focusScore,
                    metadataJson: span.metadataJson
                )
            )
            updated += 1
        }
        return updated
    }

    func closeOpenSpans(at date: Date) throws -> Int {
        let open = try openSpans()
        for var span in open {
            span.endedAt = date
            try upsertSpan(span)
        }
        return open.count
    }

    func deleteSpans(inRange start: Date, to end: Date) throws -> Int {
        try delete(
            sql: "DELETE FROM activity_spans WHERE started_at >= ? AND started_at < ?;",
            bindings: [.double(start.timeIntervalSince1970), .double(end.timeIntervalSince1970)]
        )
    }

    func deleteInterruptions(before cutoff: Date) throws -> Int {
        try delete(
            sql: "DELETE FROM interruptions WHERE timestamp < ?;",
            bindings: [.double(cutoff.timeIntervalSince1970)]
        )
    }

    func deleteFocusBlocks(before cutoff: Date) throws -> Int {
        try delete(
            sql: "DELETE FROM focus_blocks WHERE started_at < ?;",
            bindings: [.double(cutoff.timeIntervalSince1970)]
        )
    }

    func spans(from start: Date, to end: Date) throws -> [NoxActivitySpan] {
        try fetchSpans(sql: """
            SELECT id, started_at, ended_at, app_name, bundle_id, window_title, context_label, category, interruptions, focus_score, metadata_json
            FROM activity_spans
            WHERE started_at < ? AND (ended_at IS NULL OR ended_at >= ?)
            ORDER BY started_at DESC;
            """, bindings: [.double(end.timeIntervalSince1970), .double(start.timeIntervalSince1970)])
    }

    func focusBlocks(from start: Date, to end: Date) throws -> [NoxFocusBlock] {
        try fetchFocusBlocks(sql: """
            SELECT id, started_at, ended_at, primary_app, primary_bundle_id, duration_ms, switch_count, intensity, continuity_score, block_kind
            FROM focus_blocks
            WHERE started_at >= ? AND started_at < ?
            ORDER BY started_at DESC;
            """, bindings: [.double(start.timeIntervalSince1970), .double(end.timeIntervalSince1970)])
    }

    func interruptions(from start: Date, to end: Date) throws -> [NoxInterruption] {
        try fetchInterruptions(sql: """
            SELECT id, timestamp, from_app, from_bundle_id, to_app, to_bundle_id, duration_ms, returned_back
            FROM interruptions
            WHERE timestamp >= ? AND timestamp < ?
            ORDER BY timestamp DESC;
            """, bindings: [.double(start.timeIntervalSince1970), .double(end.timeIntervalSince1970)])
    }

    func searchSpans(
        from start: Date,
        to end: Date,
        query: String
    ) throws -> [NoxActivitySpan] {
        let pattern = "%\(query.lowercased())%"
        return try fetchSpans(sql: """
            SELECT id, started_at, ended_at, app_name, bundle_id, window_title, context_label, category, interruptions, focus_score, metadata_json
            FROM activity_spans
            WHERE started_at < ? AND (ended_at IS NULL OR ended_at >= ?)
            AND (
                lower(app_name) LIKE ? OR
                lower(context_label) LIKE ? OR
                lower(category) LIKE ? OR
                lower(window_title) LIKE ?
            )
            ORDER BY started_at DESC;
            """, bindings: [
            .double(end.timeIntervalSince1970),
            .double(start.timeIntervalSince1970),
            .text(pattern),
            .text(pattern),
            .text(pattern),
            .text(pattern)
        ])
    }

    private enum Binding {
        case text(String)
        case textOptional(String?)
        case double(Double)
        case doubleOptional(Double?)
        case int(Int)
        case doubleValue(Double)
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

    @discardableResult
    private func delete(sql: String, bindings: [Binding]) throws -> Int {
        try execute(sql: sql, bindings: bindings)
        return Int(sqlite3_changes(db))
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
            case .doubleValue(let value):
                sqlite3_bind_double(statement, position, value)
            }
        }
    }

    private func fetchSpans(sql: String, bindings: [Binding] = []) throws -> [NoxActivitySpan] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.queryFailed
        }
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)

        var items: [NoxActivitySpan] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = String(cString: sqlite3_column_text(statement, 0))
            let started = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
            let ended = columnOptionalDouble(statement, 2).map { Date(timeIntervalSince1970: $0) }
            let appName = String(cString: sqlite3_column_text(statement, 3))
            let bundleId = String(cString: sqlite3_column_text(statement, 4))
            let windowTitle = columnOptionalString(statement, 5)
            let contextLabel = columnOptionalString(statement, 6)
            let storedCategory = NoxActivityCategory(rawValue: String(cString: sqlite3_column_text(statement, 7))) ?? .general
            let category = NoxActivityCategory.resolving(
                stored: storedCategory,
                appName: appName,
                bundleId: bundleId,
                windowTitle: windowTitle
            )
            let interruptions = Int(sqlite3_column_int(statement, 8))
            let focusScore = sqlite3_column_double(statement, 9)
            let metadata = columnOptionalString(statement, 10)
            items.append(
                NoxActivitySpan(
                    id: id,
                    startedAt: started,
                    endedAt: ended,
                    appName: appName,
                    bundleId: bundleId,
                    windowTitle: windowTitle,
                    contextLabel: contextLabel,
                    category: category,
                    interruptions: interruptions,
                    focusScore: focusScore,
                    metadataJson: metadata
                )
            )
        }
        return items
    }

    private func fetchFocusBlocks(sql: String, bindings: [Binding]) throws -> [NoxFocusBlock] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.queryFailed
        }
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)

        var items: [NoxFocusBlock] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = String(cString: sqlite3_column_text(statement, 0))
            let started = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
            let ended = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
            let primaryApp = String(cString: sqlite3_column_text(statement, 3))
            let bundleId = String(cString: sqlite3_column_text(statement, 4))
            let durationMs = Int(sqlite3_column_int(statement, 5))
            let switchCount = Int(sqlite3_column_int(statement, 6))
            let intensity = sqlite3_column_double(statement, 7)
            let continuity = sqlite3_column_double(statement, 8)
            let kind = NoxFocusBlockKind(rawValue: String(cString: sqlite3_column_text(statement, 9))) ?? .focused
            items.append(
                NoxFocusBlock(
                    id: id,
                    startedAt: started,
                    endedAt: ended,
                    primaryApp: primaryApp,
                    primaryBundleId: bundleId,
                    durationMs: durationMs,
                    switchCount: switchCount,
                    intensity: intensity,
                    continuityScore: continuity,
                    kind: kind
                )
            )
        }
        return items
    }

    private func fetchInterruptions(sql: String, bindings: [Binding]) throws -> [NoxInterruption] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.queryFailed
        }
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)

        var items: [NoxInterruption] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            items.append(
                NoxInterruption(
                    id: String(cString: sqlite3_column_text(statement, 0)),
                    timestamp: Date(timeIntervalSince1970: sqlite3_column_double(statement, 1)),
                    fromApp: String(cString: sqlite3_column_text(statement, 2)),
                    fromBundleId: String(cString: sqlite3_column_text(statement, 3)),
                    toApp: String(cString: sqlite3_column_text(statement, 4)),
                    toBundleId: String(cString: sqlite3_column_text(statement, 5)),
                    durationMs: Int(sqlite3_column_int(statement, 6)),
                    returnedBack: sqlite3_column_int(statement, 7) == 1
                )
            )
        }
        return items
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

enum NoxMemoryStoreError: Error {
    case openFailed
    case execFailed
    case queryFailed
}
