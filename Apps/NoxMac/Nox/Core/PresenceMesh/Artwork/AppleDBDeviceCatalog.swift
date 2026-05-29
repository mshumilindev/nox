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

actor AppleDBDeviceCatalog {
    static let shared = AppleDBDeviceCatalog()

    private var memory: [String: AppleDBDeviceRecord] = [:]
    private let base = URL(string: "https://api.appledb.dev/device/")!

    func record(for deviceKey: String) async -> AppleDBDeviceRecord? {
        let key = deviceKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }
        if let hit = memory[key] { return hit }
        if let disk = await DeviceArtworkCache.shared.deviceRecord(deviceKey: key) {
            memory[key] = disk
            return disk
        }
        guard let url = URL(string: "\(key).json", relativeTo: base) else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let record = try JSONDecoder().decode(AppleDBDeviceRecord.self, from: data)
            memory[key] = record
            await DeviceArtworkCache.shared.storeDeviceRecord(record, deviceKey: key)
            return record
        } catch {
            return nil
        }
    }
}
