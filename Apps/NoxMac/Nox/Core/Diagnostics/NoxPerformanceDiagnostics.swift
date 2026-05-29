import Foundation
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

struct NoxPerformanceDiagnosticsSnapshot: Equatable, Sendable {
    let panelOpen: Bool
    let visualEffectsActive: Bool
    let activeWatchers: [String]
    let recentEventIngestionRatePerMinute: Double
    let timelineWriteBatchSize: Int
    let timelineWriteFrequencyDescription: String
    let liveSignalBufferSize: Int
    let recentBundleBufferSize: Int
    let notes: [String]
}

@MainActor
enum NoxPerformanceDiagnostics {
    static func snapshot(
        panelOpen: Bool,
        presencePageActive: Bool,
        permissionPollingActive: Bool,
        interactionSamplingActive: Bool,
        semanticHeartbeatActive: Bool,
        maintenanceLoopActive: Bool,
        liveSignalBufferSize: Int,
        recentBundleBufferSize: Int,
        recentEventIngestionRatePerMinute: Double = 0,
        timelineWriteBatchSize: Int = 1
    ) -> NoxPerformanceDiagnosticsSnapshot {
        var watchers: [String] = []
        if permissionPollingActive { watchers.append("permission-polling/5s") }
        if interactionSamplingActive { watchers.append("interaction-sampling/2s") }
        if semanticHeartbeatActive { watchers.append("semantic-heartbeat/3s") }
        if maintenanceLoopActive { watchers.append("memory-maintenance") }
        if presencePageActive { watchers.append("presence-discovery/60s") }

        return NoxPerformanceDiagnosticsSnapshot(
            panelOpen: panelOpen,
            visualEffectsActive: panelOpen || presencePageActive,
            activeWatchers: watchers,
            recentEventIngestionRatePerMinute: recentEventIngestionRatePerMinute,
            timelineWriteBatchSize: timelineWriteBatchSize,
            timelineWriteFrequencyDescription: "event-driven; dashboard reload coalesced",
            liveSignalBufferSize: liveSignalBufferSize,
            recentBundleBufferSize: recentBundleBufferSize,
            notes: [
                "Release diagnostics are passive snapshots only.",
                "Optimizations must preserve event capture and persistence semantics."
            ]
        )
    }
}
