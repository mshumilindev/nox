import Foundation

nonisolated struct DeviceArtworkResult: Sendable, Equatable {
    let tier: DeviceArtworkTier
    let imageData: Data?
    let showsConcreteAppleDevice: Bool

    static let generic = DeviceArtworkResult(tier: .generic, imageData: nil, showsConcreteAppleDevice: false)
}

/// AppleDB + apple-device-images resolver (model → cache → family → generic).
actor DeviceArtworkResolver {
    static let shared = DeviceArtworkResolver()

    private var inFlight: [String: Task<DeviceArtworkResult, Never>] = [:]

    func resolve(_ identity: NoxPresenceHardwareIdentity) async -> DeviceArtworkResult {
        let key = identity.cacheKey
        if let task = inFlight[key] { return await task.value }
        let task = Task { await resolveNow(identity) }
        inFlight[key] = task
        defer { inFlight[key] = nil }
        return await task.value
    }

    private func resolveNow(_ identity: NoxPresenceHardwareIdentity) async -> DeviceArtworkResult {
        guard identity.showsConcreteAppleDevice else { return .generic }

        switch identity.confidence {
        case .exact:
            if let deviceKey = identity.deviceKey,
               let data = await load(deviceKey: deviceKey, colorKey: identity.colorKey, tier: .modelSpecific) {
                return DeviceArtworkResult(tier: .modelSpecific, imageData: data, showsConcreteAppleDevice: true)
            }
            if let familyKey = NoxPresenceFamilyArtwork.imageKey(for: identity.fallbackKind),
               familyKey != identity.deviceKey,
               let data = await load(deviceKey: familyKey, colorKey: nil, tier: .family) {
                return DeviceArtworkResult(tier: .family, imageData: data, showsConcreteAppleDevice: true)
            }
        case .family:
            if let familyKey = NoxPresenceFamilyArtwork.imageKey(for: identity.fallbackKind),
               let data = await load(deviceKey: familyKey, colorKey: identity.colorKey, tier: .family) {
                return DeviceArtworkResult(tier: .family, imageData: data, showsConcreteAppleDevice: true)
            }
        case .generic:
            break
        }
        return .generic
    }

    private func load(deviceKey: String, colorKey: String?, tier: DeviceArtworkTier) async -> Data? {
        var color = colorKey ?? NoxPresenceFamilyArtwork.defaultColor(for: deviceKey)
        var imageKey = deviceKey
        if let record = await AppleDBDeviceCatalog.shared.record(for: deviceKey) {
            imageKey = record.resolvedImageKey
            if let preferred = record.preferredColorKey {
                color = preferred
            }
        }

        let urls = DeviceArtworkURLBuilder.imageURLs(deviceKey: imageKey, colorKey: color)
        for url in urls {
            if let cached = await DeviceArtworkCache.shared.imageData(for: url) {
                return cached
            }
        }
        for url in urls {
            if let cached = await DeviceArtworkCache.shared.imageData(for: url) { return cached }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                      DeviceArtworkImageDecoder.decode(data) != nil else { continue }
                await DeviceArtworkCache.shared.storeImageData(data, for: url)
                return data
            } catch {
                continue
            }
        }
        _ = tier
        return nil
    }
}
