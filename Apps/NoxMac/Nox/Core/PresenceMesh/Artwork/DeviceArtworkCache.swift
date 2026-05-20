import Foundation
import CryptoKit
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

nonisolated enum DeviceArtworkTier: String, Sendable {
    case modelSpecific
    case cached
    case family
    case generic
}

actor DeviceArtworkCache {
    static let shared = DeviceArtworkCache()

    private let memory = NSCache<NSString, NSData>()
    private let imagesDirectory: URL
    private let devicesDirectory: URL

    init() {
        let root = NoxPersistencePaths.meshDataDirectory.appendingPathComponent("ArtworkCache", isDirectory: true)
        imagesDirectory = root.appendingPathComponent("images", isDirectory: true)
        devicesDirectory = root.appendingPathComponent("devices", isDirectory: true)
        memory.countLimit = 128
        memory.totalCostLimit = 64 * 1024 * 1024
        NoxPersistencePaths.ensureDirectory(at: imagesDirectory)
        NoxPersistencePaths.ensureDirectory(at: devicesDirectory)
    }

    func imageData(for url: URL) -> Data? {
        let key = fileKey(for: url)
        if let data = memory.object(forKey: key as NSString) {
            return data as Data
        }
        let file = imagesDirectory.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: file), !data.isEmpty else { return nil }
        memory.setObject(data as NSData, forKey: key as NSString, cost: data.count)
        return data
    }

    func storeImageData(_ data: Data, for url: URL) {
        let key = fileKey(for: url)
        memory.setObject(data as NSData, forKey: key as NSString, cost: data.count)
        try? data.write(to: imagesDirectory.appendingPathComponent(key), options: .atomic)
    }

    func deviceRecord(deviceKey: String) -> AppleDBDeviceRecord? {
        let file = devicesDirectory.appendingPathComponent("\(safe(deviceKey)).json")
        guard let data = try? Data(contentsOf: file) else { return nil }
        return try? JSONDecoder().decode(AppleDBDeviceRecord.self, from: data)
    }

    func storeDeviceRecord(_ record: AppleDBDeviceRecord, deviceKey: String) {
        let file = devicesDirectory.appendingPathComponent("\(safe(deviceKey)).json")
        guard let data = try? JSONEncoder().encode(record) else { return }
        try? data.write(to: file, options: .atomic)
    }

    private func fileKey(for url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func safe(_ value: String) -> String {
        value.replacingOccurrences(of: "/", with: "_")
    }
}
