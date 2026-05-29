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

@MainActor
final class NoxLiveSignalBuffer {
    private let capacity: Int
    private(set) var signals: [NoxLiveSignal] = []

    init(capacity: Int = NoxRetentionPolicyDefaults.hot.liveSignalCapacity) {
        self.capacity = capacity
    }

    func prepend(_ signal: NoxLiveSignal) {
        if signals.contains(where: { $0.id == signal.id }) { return }
        guard NoxLiveSignalDeduplicator.shouldAccept(signal, in: signals) else { return }
        signals.insert(signal, at: 0)
        trimToCapacity()
    }

    func prependUniqueTexts(_ newSignals: [NoxLiveSignal]) {
        for signal in newSignals.reversed() {
            prepend(signal)
        }
    }

    func replaceAll(_ newSignals: [NoxLiveSignal]) {
        signals = Array(newSignals.prefix(capacity))
    }

    func visibleSignals(
        at date: Date = Date(),
        capabilities: NoxCapabilityState
    ) -> [NoxLiveSignal] {
        pruneExpired(at: date)
        reconcile(capabilities: capabilities)
        return signals
    }

    /// Instant live pulse from the context pipeline — replaces stale semantic lines.
    func replaceLivePulse(label: String, at date: Date = Date()) {
        signals.removeAll { signal in
            signal.id.hasPrefix("pulse-live-") || signal.id.hasPrefix("semantic-")
        }
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        signals.insert(
            NoxLiveSignal(
                id: "pulse-live-current",
                timestamp: date,
                text: trimmed,
                kind: .awareness,
                lifecycle: .transient(40)
            ),
            at: 0
        )
        trimToCapacity()
    }

    func reconcile(capabilities: NoxCapabilityState) {
        if capabilities.windowAwarenessAvailable {
            signals.removeAll { signal in
                signal.kind == .permission &&
                    signal.text == NoxLiveSignal.limitedObservationText
            }
        }

        if capabilities.appAwarenessAvailable {
            let hasActivitySignals = signals.contains { $0.kind == .app || $0.kind == .window }
            if hasActivitySignals {
                signals.removeAll { signal in
                    signal.kind == .awareness &&
                        signal.text == "Passive viewing"
                }
            }
        }
    }

    private func pruneExpired(at date: Date) {
        signals.removeAll { signal in
            guard case .transient(let ttl) = signal.lifecycle else { return false }
            return date.timeIntervalSince(signal.timestamp) > ttl
        }
    }

    private func trimToCapacity() {
        if signals.count > capacity {
            signals.removeLast(signals.count - capacity)
        }
    }
}
