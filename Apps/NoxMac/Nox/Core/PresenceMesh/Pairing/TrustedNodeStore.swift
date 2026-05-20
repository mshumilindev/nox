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

/// Persists trusted mesh nodes locally per profile.
final class TrustedNodeStore: @unchecked Sendable {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var nodes: [NoxTrustedNode] = []
    private let lock = NSLock()

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        loadFromDisk()
    }

    private var storeURL: URL {
        NoxPersistencePaths.meshDataDirectory.appendingPathComponent("trusted_nodes.json")
    }

    func all() -> [NoxTrustedNode] {
        lock.lock()
        defer { lock.unlock() }
        return nodes
    }

    func trusted(deviceId: String) -> NoxTrustedNode? {
        lock.lock()
        defer { lock.unlock() }
        return nodes.first { $0.trustedNodeId == deviceId }
    }

    func isTrusted(deviceId: String) -> Bool {
        trusted(deviceId: deviceId) != nil
    }

    @discardableResult
    func upsert(_ node: NoxTrustedNode) -> NoxTrustedNode {
        lock.lock()
        if let idx = nodes.firstIndex(where: { $0.trustedNodeId == node.trustedNodeId }) {
            nodes[idx] = node
        } else {
            nodes.append(node)
        }
        let snapshot = nodes
        lock.unlock()
        persist(snapshot)
        return node
    }

    func touch(deviceId: String) {
        lock.lock()
        guard let idx = nodes.firstIndex(where: { $0.trustedNodeId == deviceId }) else {
            lock.unlock()
            return
        }
        nodes[idx].lastSeenAt = Date()
        let snapshot = nodes
        lock.unlock()
        persist(snapshot)
    }

    func remove(deviceId: String) {
        lock.lock()
        nodes.removeAll { $0.trustedNodeId == deviceId }
        let snapshot = nodes
        lock.unlock()
        persist(snapshot)
    }

    func reset() {
        lock.lock()
        nodes.removeAll()
        lock.unlock()
        try? FileManager.default.removeItem(at: storeURL)
    }

    private func loadFromDisk() {
        NoxPersistencePaths.ensureDirectory(at: NoxPersistencePaths.meshDataDirectory)
        guard let data = try? Data(contentsOf: storeURL),
              let loaded = try? decoder.decode([NoxTrustedNode].self, from: data) else { return }
        lock.lock()
        nodes = loaded
        lock.unlock()
    }

    private func persist(_ snapshot: [NoxTrustedNode]) {
        NoxPersistencePaths.ensureDirectory(at: NoxPersistencePaths.meshDataDirectory)
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }
}
