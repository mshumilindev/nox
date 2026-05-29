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

actor NoxContinuityThreadStore {
    private var db: OpaquePointer?
    private let dbURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        NoxPersistencePaths.ensureDirectory()
        dbURL = NoxPersistencePaths.databaseURL
    }

    func open() throws {
        if db != nil { return }
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            throw NoxMemoryStoreError.openFailed
        }
        try execute(sql: """
            CREATE TABLE IF NOT EXISTS continuity_threads (
                id TEXT PRIMARY KEY,
                semantic_type TEXT NOT NULL,
                title TEXT NOT NULL,
                dominant_apps TEXT,
                dominant_categories TEXT,
                dominant_domains TEXT,
                continuity_signature TEXT NOT NULL,
                first_seen_at REAL NOT NULL,
                last_seen_at REAL NOT NULL,
                total_active_duration_ms INTEGER NOT NULL,
                total_sessions INTEGER NOT NULL,
                total_resumptions INTEGER NOT NULL,
                continuity_strength REAL NOT NULL,
                recurrence_strength REAL NOT NULL,
                interruption_pattern TEXT,
                current_status TEXT NOT NULL,
                recent_memory_ids TEXT,
                linked_span_ids TEXT,
                linked_session_ids TEXT,
                supporting_signals_json TEXT,
                confidence REAL NOT NULL,
                last_resumed_at REAL,
                temporal_patterns_json TEXT,
                decay_state TEXT NOT NULL,
                sensitivity_level TEXT NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_continuity_last_seen ON continuity_threads(last_seen_at DESC);
            CREATE INDEX IF NOT EXISTS idx_continuity_type ON continuity_threads(semantic_type);
            """)
    }

    func upsert(_ thread: NoxContinuityThread) throws {
        let signatureJson = try encode(thread.continuitySignature)
        let signalsJson = try encode(thread.supportingSignals)
        try execute(
            sql: """
            INSERT INTO continuity_threads (
                id, semantic_type, title, dominant_apps, dominant_categories, dominant_domains,
                continuity_signature, first_seen_at, last_seen_at, total_active_duration_ms,
                total_sessions, total_resumptions, continuity_strength, recurrence_strength,
                interruption_pattern, current_status, recent_memory_ids, linked_span_ids,
                linked_session_ids, supporting_signals_json, confidence, last_resumed_at,
                temporal_patterns_json, decay_state, sensitivity_level
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                semantic_type=excluded.semantic_type,
                title=excluded.title,
                dominant_apps=excluded.dominant_apps,
                dominant_categories=excluded.dominant_categories,
                dominant_domains=excluded.dominant_domains,
                continuity_signature=excluded.continuity_signature,
                last_seen_at=excluded.last_seen_at,
                total_active_duration_ms=excluded.total_active_duration_ms,
                total_sessions=excluded.total_sessions,
                total_resumptions=excluded.total_resumptions,
                continuity_strength=excluded.continuity_strength,
                recurrence_strength=excluded.recurrence_strength,
                interruption_pattern=excluded.interruption_pattern,
                current_status=excluded.current_status,
                recent_memory_ids=excluded.recent_memory_ids,
                linked_span_ids=excluded.linked_span_ids,
                linked_session_ids=excluded.linked_session_ids,
                supporting_signals_json=excluded.supporting_signals_json,
                confidence=excluded.confidence,
                last_resumed_at=excluded.last_resumed_at,
                temporal_patterns_json=excluded.temporal_patterns_json,
                decay_state=excluded.decay_state,
                sensitivity_level=excluded.sensitivity_level;
            """,
            bindings: [
                .text(thread.id),
                .text(thread.semanticType.rawValue),
                .text(thread.title),
                .text(thread.dominantApps.joined(separator: ",")),
                .text(thread.dominantCategories.joined(separator: ",")),
                .text(thread.dominantDomains.joined(separator: ",")),
                .text(signatureJson),
                .double(thread.firstSeenAt.timeIntervalSince1970),
                .double(thread.lastSeenAt.timeIntervalSince1970),
                .int(thread.totalActiveDurationMs),
                .int(thread.totalSessions),
                .int(thread.totalResumptions),
                .double(thread.continuityStrength),
                .double(thread.recurrenceStrength),
                .text(thread.interruptionPattern),
                .text(thread.currentStatus.rawValue),
                .text(thread.recentMemoryIds.joined(separator: ",")),
                .text(thread.linkedSpanIds.joined(separator: ",")),
                .text(thread.linkedSessionIds.joined(separator: ",")),
                .text(signalsJson),
                .double(thread.confidence),
                .doubleOptional(thread.lastResumedAt?.timeIntervalSince1970),
                .text(thread.temporalPatterns.joined(separator: ",")),
                .text(thread.decayState.rawValue),
                .text(thread.sensitivityLevel.rawValue)
            ]
        )
    }

    func thread(id: String) throws -> NoxContinuityThread? {
        let rows = try query(sql: "SELECT * FROM continuity_threads WHERE id = ? LIMIT 1;", bindings: [.text(id)])
        return rows.first
    }

    func activeCandidates(since: Date, limit: Int = 40) throws -> [NoxContinuityThread] {
        try query(
            sql: """
            SELECT * FROM continuity_threads
            WHERE last_seen_at >= ? AND decay_state != 'archived'
            ORDER BY last_seen_at DESC
            LIMIT ?;
            """,
            bindings: [.double(since.timeIntervalSince1970), .int(limit)]
        )
    }

    func threads(from start: Date, to end: Date) throws -> [NoxContinuityThread] {
        try query(
            sql: """
            SELECT * FROM continuity_threads
            WHERE last_seen_at >= ? AND first_seen_at <= ?
            ORDER BY continuity_strength DESC, last_seen_at DESC
            LIMIT 16;
            """,
            bindings: [.double(start.timeIntervalSince1970), .double(end.timeIntervalSince1970)]
        )
    }

    func applyDecayUpdates(_ threads: [NoxContinuityThread]) throws {
        for thread in threads {
            try upsert(thread)
        }
    }

    // MARK: - Private

    private func query(sql: String, bindings: [Binding]) throws -> [NoxContinuityThread] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NoxMemoryStoreError.queryFailed
        }
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)
        var results: [NoxContinuityThread] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            if let thread = try rowToThread(statement) {
                results.append(thread)
            }
        }
        return results
    }

    private func rowToThread(_ statement: OpaquePointer?) throws -> NoxContinuityThread? {
        guard let statement else { return nil }
        let id = columnText(statement, 0)
        let semanticType = NoxContinuitySemanticType(rawValue: columnText(statement, 1)) ?? .general
        let title = columnText(statement, 2)
        let apps = splitCSV(columnText(statement, 3))
        let categories = splitCSV(columnText(statement, 4))
        let domains = splitCSV(columnText(statement, 5))
        let signatureJson = columnText(statement, 6)
        let signature = try decode(NoxContinuitySignature.self, from: signatureJson)
        let firstSeen = Date(timeIntervalSince1970: sqlite3_column_double(statement, 7))
        let lastSeen = Date(timeIntervalSince1970: sqlite3_column_double(statement, 8))
        let durationMs = Int(sqlite3_column_int(statement, 9))
        let sessions = Int(sqlite3_column_int(statement, 10))
        let resumptions = Int(sqlite3_column_int(statement, 11))
        let strength = sqlite3_column_double(statement, 12)
        let recurrence = sqlite3_column_double(statement, 13)
        let interruption = columnText(statement, 14)
        let status = NoxContinuityStatus(rawValue: columnText(statement, 15)) ?? .paused
        let memoryIds = splitCSV(columnText(statement, 16))
        let spanIds = splitCSV(columnText(statement, 17))
        let sessionIds = splitCSV(columnText(statement, 18))
        let signalsJson = columnText(statement, 19)
        let signals = (try? decode([NoxContinuityMatchComponent].self, from: signalsJson)) ?? []
        let confidence = sqlite3_column_double(statement, 20)
        let lastResumed = sqlite3_column_type(statement, 21) == SQLITE_NULL
            ? nil
            : Date(timeIntervalSince1970: sqlite3_column_double(statement, 21))
        let patterns = splitCSV(columnText(statement, 22))
        let decay = NoxContinuityDecayState(rawValue: columnText(statement, 23)) ?? .fading
        let sensitivity = NoxSensitivityLevel(rawValue: columnText(statement, 24)) ?? .normal

        return NoxContinuityThread(
            id: id,
            semanticType: semanticType,
            title: title,
            dominantApps: apps,
            dominantCategories: categories,
            dominantDomains: domains,
            continuitySignature: signature,
            firstSeenAt: firstSeen,
            lastSeenAt: lastSeen,
            totalActiveDurationMs: durationMs,
            totalSessions: sessions,
            totalResumptions: resumptions,
            continuityStrength: strength,
            recurrenceStrength: recurrence,
            interruptionPattern: interruption,
            currentStatus: status,
            recentMemoryIds: memoryIds,
            linkedSpanIds: spanIds,
            linkedSessionIds: sessionIds,
            supportingSignals: signals,
            confidence: confidence,
            lastResumedAt: lastResumed,
            temporalPatterns: patterns,
            decayState: decay,
            sensitivityLevel: sensitivity
        )
    }

    private func columnText(_ statement: OpaquePointer?, _ index: Int32) -> String {
        guard let c = sqlite3_column_text(statement, index) else { return "" }
        return String(cString: c)
    }

    private func splitCSV(_ value: String) -> [String] {
        value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private func encode<T: Encodable>(_ value: T) throws -> String {
        let data = try encoder.encode(value)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        let data = Data(json.utf8)
        return try decoder.decode(type, from: data)
    }

    private enum Binding {
        case text(String)
        case double(Double)
        case doubleOptional(Double?)
        case int(Int)
    }

    @discardableResult
    func deleteAll() throws -> Int {
        try execute(sql: "DELETE FROM continuity_threads;")
        return Int(sqlite3_changes(db))
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

    private func bind(_ bindings: [Binding], to statement: OpaquePointer?) throws {
        for (index, binding) in bindings.enumerated() {
            let i = Int32(index + 1)
            switch binding {
            case .text(let value):
                sqlite3_bind_text(statement, i, value, -1, noxSQLiteTransient)
            case .double(let value):
                sqlite3_bind_double(statement, i, value)
            case .doubleOptional(let value):
                if let value { sqlite3_bind_double(statement, i, value) } else { sqlite3_bind_null(statement, i) }
            case .int(let value):
                sqlite3_bind_int(statement, i, Int32(value))
            }
        }
    }
}
