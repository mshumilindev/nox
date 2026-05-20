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

struct NoxActivitySignalTracker {
    private var switchTimestamps: [Date] = []
    private var currentBundleId: String?
    private var currentAppStartedAt: Date = Date()
    private var firstSignalAt: Date?

    mutating func recordSnapshot(_ snapshot: NoxActivitySnapshot) {
        if firstSignalAt == nil {
            firstSignalAt = snapshot.capturedAt
        }

        if let currentBundleId, currentBundleId != snapshot.bundleId {
            switchTimestamps.append(snapshot.capturedAt)
            switchTimestamps = switchTimestamps.filter {
                snapshot.capturedAt.timeIntervalSince($0) <= NoxPresenceRules.distractedWindowSeconds
            }
        }

        if currentBundleId != snapshot.bundleId {
            currentBundleId = snapshot.bundleId
            currentAppStartedAt = snapshot.capturedAt
        }
    }

    func timeInCurrentApp(at date: Date = Date()) -> TimeInterval {
        date.timeIntervalSince(currentAppStartedAt)
    }

    func recentSwitchCount(at date: Date = Date()) -> Int {
        switchTimestamps.filter { date.timeIntervalSince($0) <= NoxPresenceRules.distractedWindowSeconds }.count
    }

    /// Down-weights old switches when the user has stayed in one app — avoids stale "fragmented" labels.
    func fragmentationSwitchCount(at date: Date = Date()) -> Int {
        let raw = recentSwitchCount(at: date)
        let inApp = timeInCurrentApp(at: date)
        if inApp >= 120 { return 0 }
        if inApp >= 60 { return max(0, raw - 3) }
        if inApp >= 30 { return max(0, raw - 1) }
        return raw
    }

    var hasEnoughSignals: Bool {
        guard let firstSignalAt else { return false }
        return Date().timeIntervalSince(firstSignalAt) >= 30
    }

    func observationContinuitySeconds(at date: Date = Date()) -> TimeInterval {
        guard let firstSignalAt else { return 0 }
        return max(0, date.timeIntervalSince(firstSignalAt))
    }

    mutating func restore(from persisted: NoxPersistedSignalTracker) {
        firstSignalAt = persisted.firstSignalAt
        currentBundleId = persisted.currentBundleId
        currentAppStartedAt = persisted.currentAppStartedAt ?? Date()
        switchTimestamps = persisted.switchTimestamps
    }

    func exportPersisted() -> NoxPersistedSignalTracker {
        NoxPersistedSignalTracker(
            firstSignalAt: firstSignalAt,
            currentBundleId: currentBundleId,
            currentAppStartedAt: currentAppStartedAt,
            switchTimestamps: switchTimestamps
        )
    }
}
