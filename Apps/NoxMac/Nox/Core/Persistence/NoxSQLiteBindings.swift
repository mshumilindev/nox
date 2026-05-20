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

/// Shared SQLite string destructor — safe across actor-isolated stores.
nonisolated let noxSQLiteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
