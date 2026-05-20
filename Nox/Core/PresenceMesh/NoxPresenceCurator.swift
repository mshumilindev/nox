import Foundation

/// Curates what may appear in Presence UI — prefer silence over wrong guesses.
nonisolated enum NoxPresenceCurator {
    private static let rejectedTokens = [
        "elmedia", "player", "vlc", "kodi", "plex", "spotify", "airplay", "raop",
        "samsung", "linux", "ubuntu", "android", "windows", "roku", "sonos",
        "chromecast", "google", "lg tv", "smart tv", "router", "printer", "nas",
        "soundbar", "receiver", "speaker", "bridge", "server", "http", "ftp",
        "bonjour", "mdns", "._", ".local", "clink-", "living room tv",
    ]

    private static let rejectedAppPatterns = [
        " video player", " media", " stream", " cast", " audio accessory",
        " screen mirror", " remote",
    ]

    /// Only real Nox mesh environments with verifiable pairing metadata.
    static func isPresentableNoxEnvironment(_ node: NoxDiscoveredNode) -> Bool {
        if isPresentableApplePresence(node) { return true }
        guard node.state != .unavailable else { return false }
        guard !node.deviceId.hasPrefix("apple-") else { return false }
        guard isValidMeshDeviceId(node.deviceId) else { return false }
        guard let name = displayEnvironmentName(node.deviceName) else { return false }
        guard !name.isEmpty else { return false }
        guard node.pairingPort > 0 else { return false }
        guard !node.publicKeyFingerprint.isEmpty else { return false }
        return true
    }

    static func isPresentableApplePresence(_ node: NoxDiscoveredNode) -> Bool {
        guard node.state == .unavailable else { return false }
        guard node.deviceId.hasPrefix("apple-") else { return false }
        guard resolvedDeviceKind(for: node) != nil else { return false }
        return displayEnvironmentName(node.deviceName) != nil
    }

    static func displayEnvironmentName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !isLowQualityNetworkLabel(trimmed) else { return nil }

        let lowered = trimmed.lowercased()
        if rejectedTokens.contains(where: { lowered.contains($0) }) { return nil }
        if rejectedAppPatterns.contains(where: { lowered.contains($0) }) { return nil }

        if let at = trimmed.firstIndex(of: "@") {
            let after = String(trimmed[trimmed.index(after: at)...]).trimmingCharacters(in: .whitespaces)
            if isLowQualityNetworkLabel(after) { return nil }
            if rejectedTokens.contains(where: { after.lowercased().contains($0) }) { return nil }
            return after
        }

        return trimmed
    }

    static func sanitizedHostName() -> String? {
        let raw = Host.current().localizedName ?? ""
        return displayEnvironmentName(raw)
    }

    static func resolvedDeviceKind(for environmentName: String) -> NoxPresenceDeviceKind? {
        NoxPresenceDeviceKind.confidentlyInfer(from: environmentName)
    }

    static func resolvedDeviceKind(for node: NoxDiscoveredNode) -> NoxPresenceDeviceKind? {
        let nameKind = resolvedDeviceKind(for: node.deviceName)
        if let rawKind = node.presenceToken.split(separator: ":").last,
           let kind = NoxPresenceDeviceKind(rawValue: String(rawKind)) {
            if let nameKind,
               isAppleMediaModelMismatch(tokenKind: kind, nameKind: nameKind) {
                return nameKind
            }
            return kind
        }
        return nameKind
    }

    static func appleDisplayName(
        rawName: String,
        model: String,
        hostName: String?,
        serviceType: String
    ) -> (String, NoxPresenceDeviceKind)? {
        let kindSource = [model, hostName ?? ""].joined(separator: " ")
        let kind = NoxPresenceDeviceKind.confidentlyInfer(from: kindSource)
            ?? mobileDeviceKind(rawName: rawName, hostName: hostName, serviceType: serviceType)
        guard let kind else { return nil }

        if let cleaned = displayEnvironmentName(rawName) {
            return (cleaned, kind)
        }

        return ("Nearby \(kind.typeLabel)", kind)
    }

    private static func mobileDeviceKind(
        rawName: String,
        hostName: String?,
        serviceType: String
    ) -> NoxPresenceDeviceKind? {
        let isAppleMobileService = serviceType == "_apple-mobdev2._tcp."
            || serviceType == "_companion-link._tcp."
        guard isAppleMobileService else { return nil }

        let identitySource = [rawName, hostName ?? ""].joined(separator: " ").lowercased()
        if identitySource.contains("iphone") { return .iPhone }
        if identitySource.contains("ipad") { return .iPad }
        return nil
    }

    private static func isValidMeshDeviceId(_ id: String) -> Bool {
        guard !id.isEmpty, !id.hasPrefix("sim-"), !id.hasPrefix("apple-") else { return false }
        return UUID(uuidString: id) != nil
    }

    private static func isAppleMediaModelMismatch(
        tokenKind: NoxPresenceDeviceKind,
        nameKind: NoxPresenceDeviceKind
    ) -> Bool {
        guard isMacFamily(nameKind) else { return false }
        return tokenKind == .appleTV || tokenKind == .homePod
    }

    private static func isMacFamily(_ kind: NoxPresenceDeviceKind) -> Bool {
        switch kind {
        case .iMac, .macBookPro, .macBookAir, .macStudio, .macMini, .mac:
            return true
        case .iPhone, .iPad, .appleWatch, .appleTV, .homePod:
            return false
        }
    }

    private static func isLowQualityNetworkLabel(_ name: String) -> Bool {
        if name.isEmpty { return true }
        let lowered = name.lowercased()
        if lowered == "nearby mac" || lowered == "mac" || lowered == "unknown" { return true }
        if lowered.range(of: #"^[a-f0-9:-]{8,}$"#, options: .regularExpression) != nil { return true }
        if lowered.contains("._") || lowered.hasSuffix(".local") { return true }
        if name.count < 2 { return true }
        let letters = name.filter(\.isLetter).count
        if letters < 2 { return true }
        return false
    }
}
