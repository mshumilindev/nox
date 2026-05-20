import Darwin
import Foundation

nonisolated enum NoxPresenceHardwareIdentityResolver {
    private static let exactKeyPattern =
        #"^(Mac|MacBookPro|MacBookAir|MacBook|Macmini|MacPro|iMac|iPhone|iPad|Watch|AppleTV|AudioAccessory|HomePod|RealityDevice)[0-9]+,[0-9]+$"#
    private static let embeddedKeyPattern =
        #"(Mac|MacBookPro|MacBookAir|MacBook|Macmini|MacPro|iMac|iPhone|iPad|Watch|AppleTV|AudioAccessory|HomePod|RealityDevice)[0-9]+,[0-9]+"#

    static func hardwareIdentity(
        for node: NoxDiscoveredNode,
        expectedKind: NoxPresenceDeviceKind? = nil
    ) -> NoxPresenceHardwareIdentity {
        let identity = if node.deviceId.hasPrefix("apple-") {
            appleIdentity(for: node)
        } else {
            noxIdentity(for: node)
        }
        return reconciled(identity: identity, node: node, expectedKind: expectedKind)
    }

    static func hardwareIdentityForLocalMac(deviceName: String) -> NoxPresenceHardwareIdentity {
        if let key = parseDeviceKey(NoxLocalMachineIdentifier.hwModel) {
            let kind = NoxPresenceDeviceKind.confidentlyInfer(from: deviceName) ?? kindForDeviceKey(key) ?? .macBookPro
            return NoxPresenceHardwareIdentity(
                confidence: .exact,
                deviceKey: key,
                colorKey: NoxPresenceFamilyArtwork.defaultColor(for: key),
                fallbackKind: kind,
                showsConcreteAppleDevice: true
            )
        }
        let kind = NoxPresenceDeviceKind.confidentlyInfer(from: deviceName) ?? .macBookPro
        return familyIdentity(kind: kind)
    }

    private static func appleIdentity(for node: NoxDiscoveredNode) -> NoxPresenceHardwareIdentity {
        if let key = parseDeviceKey(node.appleDeviceIdentifier) ?? parseDeviceKey(node.appleModel),
           let kind = kindForDeviceKey(key) {
            if let nameKind = NoxPresenceDeviceKind.confidentlyInfer(from: node.deviceName),
               isAppleMediaModelMismatch(modelKind: kind, nameKind: nameKind) {
                return familyIdentity(kind: nameKind)
            }
            guard node.appleDiscoverySource?.trustsHardwareFields == true
                    || node.appleDiscoverySource == .airplay
                    || node.appleDiscoverySource == .raop else {
                return .generic(fallbackKind: kind)
            }
            return NoxPresenceHardwareIdentity(
                confidence: .exact,
                deviceKey: key,
                colorKey: nil,
                fallbackKind: kind,
                showsConcreteAppleDevice: true
            )
        }
        if let source = node.appleDiscoverySource,
           (source == .airplay || source == .raop),
           let kind = trustedMediaEndpointFamilyKind(for: node) {
            return familyIdentity(kind: kind)
        }
        guard node.appleDiscoverySource?.trustsHardwareFields == true else {
            return .generic()
        }
        if let key = parseDeviceKey(node.appleDeviceIdentifier) ?? parseDeviceKey(node.appleModel) {
            let kind = kindForDeviceKey(key) ?? NoxPresenceDeviceKind.confidentlyInfer(from: node.deviceName) ?? .mac
            return NoxPresenceHardwareIdentity(
                confidence: .exact,
                deviceKey: key,
                colorKey: nil,
                fallbackKind: kind,
                showsConcreteAppleDevice: true
            )
        }
        if let kind = trustedFamilyKind(for: node) {
            return familyIdentity(kind: kind)
        }
        return .generic()
    }

    private static func noxIdentity(for node: NoxDiscoveredNode) -> NoxPresenceHardwareIdentity {
        guard let kind = NoxPresenceCurator.resolvedDeviceKind(for: node) else { return .generic() }
        return familyIdentity(kind: kind)
    }

    private static func reconciled(
        identity: NoxPresenceHardwareIdentity,
        node: NoxDiscoveredNode,
        expectedKind: NoxPresenceDeviceKind?
    ) -> NoxPresenceHardwareIdentity {
        guard let expectedKind, identity.fallbackKind != expectedKind else { return identity }
        guard NoxPresenceDeviceKind.confidentlyInfer(from: node.deviceName) == expectedKind else { return identity }
        if isAppleMediaModelMismatch(modelKind: identity.fallbackKind, nameKind: expectedKind) {
            return familyIdentity(kind: expectedKind)
        }
        return identity
    }

    private static func trustedFamilyKind(for node: NoxDiscoveredNode) -> NoxPresenceDeviceKind? {
        guard let source = node.appleDiscoverySource, source.trustsHardwareFields else { return nil }
        switch source {
        case .mobileSync, .companionLink:
            let text = [node.deviceName, node.appleModel ?? ""].joined(separator: " ").lowercased()
            if text.contains("ipad") { return .iPad }
            if text.contains("iphone") { return .iPhone }
            return nil
        case .bluetoothContinuity:
            return .iPhone
        case .deviceInfo:
            return NoxPresenceCurator.resolvedDeviceKind(for: node.deviceName)
                ?? NoxPresenceCurator.resolvedDeviceKind(for: node.appleModel ?? "")
        case .airplay, .raop:
            return trustedMediaEndpointFamilyKind(for: node)
        case .noxMesh, .homeKit:
            return nil
        }
    }

    private static func trustedMediaEndpointFamilyKind(for node: NoxDiscoveredNode) -> NoxPresenceDeviceKind? {
        let model = node.appleModel ?? ""
        if model.contains("AudioAccessory") || model.contains("HomePod") {
            return .homePod
        }
        if model.contains("AppleTV") || model.contains("J105") || model.contains("J42") {
            return .appleTV
        }
        return nil
    }

    private static func familyIdentity(kind: NoxPresenceDeviceKind) -> NoxPresenceHardwareIdentity {
        let key = NoxPresenceFamilyArtwork.imageKey(for: kind)
        return NoxPresenceHardwareIdentity(
            confidence: .family,
            deviceKey: key,
            colorKey: key.map { NoxPresenceFamilyArtwork.defaultColor(for: $0) },
            fallbackKind: kind,
            showsConcreteAppleDevice: true
        )
    }

    private static func parseDeviceKey(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.range(of: exactKeyPattern, options: .regularExpression) != nil { return trimmed }
        guard let regex = try? NSRegularExpression(pattern: embeddedKeyPattern) else { return nil }
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        guard let match = regex.firstMatch(in: trimmed, range: range),
              let swiftRange = Range(match.range, in: trimmed) else { return nil }
        return String(trimmed[swiftRange])
    }

    private static func kindForDeviceKey(_ key: String) -> NoxPresenceDeviceKind? {
        if key.hasPrefix("MacBookPro") { return .macBookPro }
        if key.hasPrefix("MacBookAir") { return .macBookAir }
        if key.hasPrefix("MacBook") { return .macBookPro }
        if key.hasPrefix("iMac") { return .iMac }
        if key.hasPrefix("Macmini") { return .macMini }
        if key.hasPrefix("MacPro") { return .macStudio }
        if key.hasPrefix("iPhone") { return .iPhone }
        if key.hasPrefix("iPad") { return .iPad }
        if key.hasPrefix("Watch") { return .appleWatch }
        if key.hasPrefix("AppleTV") { return .appleTV }
        if key.hasPrefix("AudioAccessory") || key.hasPrefix("HomePod") { return .homePod }
        if key.hasPrefix("Mac") { return .macBookPro }
        return nil
    }

    private static func isAppleMediaModelMismatch(
        modelKind: NoxPresenceDeviceKind,
        nameKind: NoxPresenceDeviceKind
    ) -> Bool {
        guard isMacFamily(nameKind) else { return false }
        return modelKind == .appleTV || modelKind == .homePod
    }

    private static func isMacFamily(_ kind: NoxPresenceDeviceKind) -> Bool {
        switch kind {
        case .iMac, .macBookPro, .macBookAir, .macStudio, .macMini, .mac:
            return true
        case .iPhone, .iPad, .appleWatch, .appleTV, .homePod:
            return false
        }
    }
}

nonisolated enum NoxLocalMachineIdentifier {
    static var hwModel: String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var bytes = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &bytes, &size, nil, 0)
        return String(cString: bytes)
    }
}
