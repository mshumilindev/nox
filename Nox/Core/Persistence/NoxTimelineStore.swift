import Foundation
import SQLite3

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

actor NoxTimelineStore {
    private var db: OpaquePointer?
    private let dbURL: URL

    init(fileManager: FileManager = .default) {
        NoxPersistencePaths.ensureDirectory()
        dbURL = NoxPersistencePaths.databaseURL
    }

    func open() throws {
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            throw NoxTimelineStoreError.openFailed
        }
        try executeScript("""
            CREATE TABLE IF NOT EXISTS timeline_events (
                id TEXT PRIMARY KEY,
                type TEXT NOT NULL,
                timestamp REAL NOT NULL,
                source TEXT NOT NULL,
                app_name TEXT,
                bundle_id TEXT,
                window_title TEXT,
                duration_ms INTEGER,
                metadata_json TEXT,
                display_text TEXT NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_timeline_timestamp ON timeline_events(timestamp DESC);
            """)
    }

    func insertEvent(from event: NoxEvent, source: String = "nox") throws {
        let fields = fields(for: event)
        let sql = """
            INSERT OR IGNORE INTO timeline_events
            (id, type, timestamp, source, app_name, bundle_id, window_title, duration_ms, metadata_json, display_text)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
        try execute(
            sql: sql,
            bindings: [
                .text(event.id.uuidString),
                .text(event.type.rawValue),
                .double(event.timestamp.timeIntervalSince1970),
                .text(source),
                .textOptional(fields.appName),
                .textOptional(fields.bundleId),
                .textOptional(fields.windowTitle),
                .intOptional(fields.durationMs),
                .textOptional(fields.metadataJson),
                .text(fields.displayText)
            ]
        )
    }

    func getRecentEvents(limit: Int = 50) throws -> [NoxTimelineRecord] {
        try fetch(sql: """
            SELECT id, type, timestamp, source, app_name, bundle_id, window_title, duration_ms, metadata_json, display_text
            FROM timeline_events
            ORDER BY timestamp DESC
            LIMIT ?;
            """, bindings: [.int(limit)])
    }

    @discardableResult
    func deleteEvents(from start: Date, to end: Date) throws -> Int {
        try execute(
            sql: "DELETE FROM timeline_events WHERE timestamp >= ? AND timestamp < ?;",
            bindings: [.double(start.timeIntervalSince1970), .double(end.timeIntervalSince1970)]
        )
        return Int(sqlite3_changes(db))
    }

    @discardableResult
    func pruneOldEvents(olderThan days: Int = 30) throws -> Int {
        let cutoff = Date().addingTimeInterval(-Double(days) * 86_400).timeIntervalSince1970
        try execute(sql: "DELETE FROM timeline_events WHERE timestamp < ?;", bindings: [.double(cutoff)])
        return Int(sqlite3_changes(db))
    }

    func shouldSkipDuplicate(appChanged bundleId: String, within seconds: TimeInterval) throws -> Bool {
        let cutoff = Date().addingTimeInterval(-seconds).timeIntervalSince1970
        let rows = try fetch(sql: """
            SELECT id FROM timeline_events
            WHERE type = 'app.changed' AND bundle_id = ? AND timestamp > ?
            LIMIT 1;
            """, bindings: [.text(bundleId), .double(cutoff)])
        return !rows.isEmpty
    }

    private struct InsertFields {
        let appName: String?
        let bundleId: String?
        let windowTitle: String?
        let durationMs: Int?
        let metadataJson: String?
        let displayText: String
    }

    private func fields(for event: NoxEvent) -> InsertFields {
        var appName: String?
        var bundleId: String?
        var windowTitle: String?
        var durationMs: Int?
        var metadataJson: String?

        switch event.payload {
        case .appChanged(let p):
            appName = p.appName
            bundleId = p.bundleId
            windowTitle = p.windowTitle
        case .windowChanged(let p):
            appName = p.appName
            bundleId = p.bundleId
            windowTitle = p.windowTitle
        case .session(let p):
            appName = p.primaryApp
            bundleId = p.primaryBundleId
            durationMs = p.durationMs
            metadataJson = "{\"confidence\":\(p.confidence),\"state\":\"\(p.state)\"}"
        case .presence(let p):
            metadataJson = "{\"previous\":\"\(p.previous)\",\"current\":\"\(p.current)\"}"
        case .permission(let p):
            metadataJson = "{\"mode\":\"\(p.mode)\"}"
        default:
            break
        }

        return InsertFields(
            appName: appName,
            bundleId: bundleId,
            windowTitle: windowTitle,
            durationMs: durationMs,
            metadataJson: metadataJson,
            displayText: NoxTimelinePresenter.displayText(for: event)
        )
    }

    private enum Binding {
        case text(String)
        case textOptional(String?)
        case double(Double)
        case int(Int)
        case intOptional(Int?)
    }

    private func execute(sql: String, bindings: [Binding] = []) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxTimelineStoreError.execFailed
        }
        defer { sqlite3_finalize(statement) }

        for (index, binding) in bindings.enumerated() {
            let position = Int32(index + 1)
            switch binding {
            case .text(let value):
                sqlite3_bind_text(statement, position, value, -1, sqliteTransient)
            case .textOptional(let value):
                if let value {
                    sqlite3_bind_text(statement, position, value, -1, sqliteTransient)
                } else {
                    sqlite3_bind_null(statement, position)
                }
            case .double(let value):
                sqlite3_bind_double(statement, position, value)
            case .int(let value):
                sqlite3_bind_int(statement, position, Int32(value))
            case .intOptional(let value):
                if let value {
                    sqlite3_bind_int(statement, position, Int32(value))
                } else {
                    sqlite3_bind_null(statement, position)
                }
            }
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw NoxTimelineStoreError.execFailed
        }
    }

    private func executeScript(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            sqlite3_free(errorMessage)
            throw NoxTimelineStoreError.execFailed
        }
    }

    private func fetch(sql: String, bindings: [Binding] = []) throws -> [NoxTimelineRecord] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxTimelineStoreError.queryFailed
        }
        defer { sqlite3_finalize(statement) }

        for (index, binding) in bindings.enumerated() {
            let position = Int32(index + 1)
            switch binding {
            case .text(let value):
                sqlite3_bind_text(statement, position, value, -1, sqliteTransient)
            case .textOptional(let value):
                if let value {
                    sqlite3_bind_text(statement, position, value, -1, sqliteTransient)
                } else {
                    sqlite3_bind_null(statement, position)
                }
            case .double(let value):
                sqlite3_bind_double(statement, position, value)
            case .int(let value):
                sqlite3_bind_int(statement, position, Int32(value))
            case .intOptional(let value):
                if let value {
                    sqlite3_bind_int(statement, position, Int32(value))
                } else {
                    sqlite3_bind_null(statement, position)
                }
            }
        }

        var records: [NoxTimelineRecord] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = columnOptionalString(statement, 0) ?? UUID().uuidString
            let type = columnOptionalString(statement, 1) ?? "unknown"
            let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
            let source = columnOptionalString(statement, 3) ?? "nox"
            let appName = columnOptionalString(statement, 4)
            let bundleId = columnOptionalString(statement, 5)
            let windowTitle = columnOptionalString(statement, 6)
            let durationMs = sqlite3_column_type(statement, 7) == SQLITE_NULL
                ? nil
                : Int(sqlite3_column_int(statement, 7))
            let metadataJson = columnOptionalString(statement, 8)
            let displayText = columnOptionalString(statement, 9) ?? ""

            records.append(
                NoxTimelineRecord(
                    id: id,
                    type: type,
                    timestamp: timestamp,
                    source: source,
                    appName: appName,
                    bundleId: bundleId,
                    windowTitle: windowTitle,
                    durationMs: durationMs,
                    metadataJson: metadataJson,
                    displayText: displayText
                )
            )
        }
        return records
    }

    private func columnOptionalString(_ statement: OpaquePointer?, _ index: Int32) -> String? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        return String(cString: sqlite3_column_text(statement, index))
    }
}

enum NoxTimelineStoreError: Error {
    case openFailed
    case execFailed
    case queryFailed
}
