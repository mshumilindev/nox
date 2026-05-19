import SQLite3

/// Shared SQLite string destructor — safe across actor-isolated stores.
nonisolated let noxSQLiteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
