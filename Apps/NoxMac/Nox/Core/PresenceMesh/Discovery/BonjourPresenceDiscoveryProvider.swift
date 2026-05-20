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

/// Publishes Nox and listens for curated Apple ecosystem presence.
final class BonjourPresenceDiscoveryProvider: NSObject, PresenceDiscoveryProvider, @unchecked Sendable {
    private let noxServiceType = "_nox._tcp."
    private let appleServiceTypes = [
        "_airplay._tcp.",
        "_raop._tcp.",
        "_companion-link._tcp.",
        "_device-info._tcp.",
        "_apple-mobdev2._tcp.",
        "_homekit._tcp.",
    ]
    private let domain = "local."

    var onNodesChanged: (@Sendable ([NoxDiscoveredNode]) -> Void)?

    private var browsers: [String: NetServiceBrowser] = [:]
    private var publisher: NetService?
    private var resolving: [String: NetService] = [:]
    private var serviceToDeviceId: [String: String] = [:]
    private var nodes: [String: NoxDiscoveredNode] = [:]
    private let queue = DispatchQueue(label: "dev.nox.mesh.discovery")
    private var debounceWork: DispatchWorkItem?
    private var localDeviceId: String?
    private var appleBrowsersActive = false

    func start(identity: NoxNodeIdentity, port: UInt16, presenceToken: String) throws {
        stop()
        localDeviceId = identity.deviceId
        appleBrowsersActive = false

        let publisher = NetService(
            domain: domain,
            type: noxServiceType,
            name: bonjourSafeName(identity.deviceName),
            port: Int32(port)
        )
        publisher.includesPeerToPeer = true
        publisher.delegate = self
        let txt: [String: String] = [
            "deviceId": identity.deviceId,
            "deviceName": identity.deviceName,
            "protocolVersion": "\(identity.protocolVersion)",
            "fingerprint": identity.publicKeyFingerprint,
            "token": presenceToken,
            "port": "\(port)",
            "systemId": identity.systemId,
        ]
        publisher.setTXTRecord(NetService.data(fromTXTRecord: txtDictionary(txt)))
        publisher.publish()
        self.publisher = publisher

        startBrowser(for: noxServiceType)

        NoxPresenceMeshDiagnostics.log("Presence mesh published; Nox browse only until Presence is open")
    }

    /// AirPlay / HomeKit browsers are for curated Apple presence — skip at idle to cut mDNS work.
    func setAppleEcosystemBrowsingActive(_ active: Bool) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.setAppleEcosystemBrowsingActive(active)
            }
            return
        }

        if active == appleBrowsersActive { return }
        appleBrowsersActive = active
        if active {
            for type in appleServiceTypes where browsers[type] == nil {
                startBrowser(for: type)
            }
            NoxPresenceMeshDiagnostics.log("Apple ecosystem browse active")
        } else {
            for type in appleServiceTypes {
                browsers[type]?.stop()
                browsers.removeValue(forKey: type)
            }
            pruneAppleOnlyNodes()
            NoxPresenceMeshDiagnostics.log("Apple ecosystem browse paused")
        }
    }

    private func startBrowser(for type: String) {
        guard browsers[type] == nil else { return }
        let browser = NetServiceBrowser()
        browser.includesPeerToPeer = true
        browser.delegate = self
        browser.searchForServices(ofType: type, inDomain: domain)
        browsers[type] = browser
    }

    private func pruneAppleOnlyNodes() {
        nodes = nodes.filter { _, node in
            node.presenceToken != "_airplay._tcp."
                && node.presenceToken != "_raop._tcp."
                && !node.deviceId.hasPrefix("apple-")
        }
        scheduleEmit()
    }

    func stop() {
        debounceWork?.cancel()
        browsers.values.forEach { $0.stop() }
        browsers.removeAll()
        publisher?.stop()
        publisher = nil
        resolving.removeAll()
        serviceToDeviceId.removeAll()
        nodes.removeAll()
        appleBrowsersActive = false
    }

    private func bonjourSafeName(_ name: String) -> String {
        let cleaned = name
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "'" }
        return cleaned.isEmpty ? "Nox" : String(cleaned.prefix(48))
    }

    private func txtDictionary(_ dict: [String: String]) -> [String: Data] {
        var encoded: [String: Data] = [:]
        for (k, v) in dict {
            encoded[k] = v.data(using: .utf8) ?? Data()
        }
        return encoded
    }

    private func parseTXT(_ data: Data?) -> [String: String] {
        guard let data else { return [:] }
        let dict = NetService.dictionary(fromTXTRecord: data)
        var out: [String: String] = [:]
        for (k, v) in dict {
            out[k] = String(data: v, encoding: .utf8) ?? ""
        }
        return out
    }

    private func scheduleEmit() {
        debounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let list = Array(self.nodes.values)
                .filter { NoxPresenceCurator.isPresentableNoxEnvironment($0) }
                .sorted {
                    if $0.state != $1.state {
                        return $0.state.sortRank < $1.state.sortRank
                    }
                    return $0.deviceName.localizedCaseInsensitiveCompare($1.deviceName) == .orderedAscending
                }
            self.onNodesChanged?(list)
        }
        debounceWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    private func upsertNoxService(service: NetService, hostName: String?, port: Int) {
        guard let txt = service.txtRecordData() else { return }
        let fields = parseTXT(txt)
        guard let deviceId = fields["deviceId"], !deviceId.isEmpty else { return }
        if deviceId == localDeviceId { return }

        let rawName = fields["deviceName"] ?? ""
        guard let deviceName = NoxPresenceCurator.displayEnvironmentName(rawName) else {
            NoxPresenceMeshDiagnostics.log("Ignored low-confidence environment label")
            return
        }

        let node = NoxDiscoveredNode(
            deviceId: deviceId,
            deviceName: deviceName,
            protocolVersion: Int(fields["protocolVersion"] ?? "1") ?? 1,
            publicKeyFingerprint: fields["fingerprint"] ?? "",
            presenceToken: fields["token"] ?? "",
            pairingPort: port > 0 ? port : Int(fields["port"] ?? "0") ?? 0,
            state: .nearby,
            lastSeenAt: Date(),
            systemId: fields["systemId"],
            hostName: hostName
        )
        guard NoxPresenceCurator.isPresentableNoxEnvironment(node) else { return }
        nodes[deviceId] = node
        serviceToDeviceId[serviceKey(service)] = deviceId
        NoxPresenceMeshDiagnostics.log("Nox environment sensed: \(deviceName)")
        scheduleEmit()
    }

    private func upsertApplePresence(service: NetService, hostName: String?, port: Int) {
        let fields = parseTXT(service.txtRecordData())
        let rawName = appleRawName(from: service)
        let model = appleModel(from: fields)
        let groupId = appleGroupIdentifier(from: fields)

        guard let candidate = NoxPresenceCurator.appleDisplayName(
            rawName: rawName,
            model: model,
            hostName: hostName,
            serviceType: service.type
        ) else { return }

        let displayName = appleDisplayName(candidateName: candidate.0, fields: fields, kind: candidate.1)
        let deviceId = appleDeviceId(
            candidateName: displayName,
            kind: candidate.1,
            hostName: hostName,
            fields: fields,
            groupId: groupId
        )
        let existing = nodes[deviceId]
        let memberNames = mergedMemberNames(existing: existing, serviceName: rawName)
        let incoming = NoxAppleDiscoverySource(bonjourServiceType: service.type)
        let source = incoming?.merged(with: existing?.appleDiscoverySource) ?? existing?.appleDiscoverySource
        let node = NoxDiscoveredNode(
            deviceId: deviceId,
            deviceName: bestDisplayName(existing: existing?.deviceName, incoming: displayName, kind: candidate.1),
            protocolVersion: 1,
            publicKeyFingerprint: "",
            presenceToken: "apple-presence:\(candidate.1.rawValue)",
            pairingPort: port,
            state: .unavailable,
            lastSeenAt: Date(),
            hostName: hostName ?? existing?.hostName,
            appleModel: model.isEmpty ? existing?.appleModel : model,
            appleDeviceIdentifier: fields["deviceid"] ?? existing?.appleDeviceIdentifier,
            appleGroupIdentifier: groupId ?? existing?.appleGroupIdentifier,
            appleGroupName: fields["gpn"] ?? existing?.appleGroupName,
            appleGroupMemberNames: memberNames,
            appleDiscoverySource: source
        )
        guard NoxPresenceCurator.isPresentableApplePresence(node) else { return }
        nodes[node.deviceId] = node
        serviceToDeviceId[serviceKey(service)] = node.deviceId
        NoxPresenceMeshDiagnostics.log("Apple ecosystem presence sensed: \(node.deviceName)")
        scheduleEmit()
    }

    private func remove(service: NetService) {
        if let deviceId = serviceToDeviceId.removeValue(forKey: serviceKey(service)) {
            let stillPresent = serviceToDeviceId.values.contains(deviceId)
            if !stillPresent {
                nodes.removeValue(forKey: deviceId)
            }
        }
        scheduleEmit()
    }

    private func serviceKey(_ service: NetService) -> String {
        "\(service.type)|\(service.name)"
    }

    private func appleRawName(from service: NetService) -> String {
        let name = service.name
        if let at = name.firstIndex(of: "@") {
            return String(name[name.index(after: at)...])
        }
        return name
    }

    private func appleModel(from fields: [String: String]) -> String {
        [
            fields["model"],
            fields["am"],
            fields["md"],
            fields["deviceid"],
            fields["manufacturer"],
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }

    private func appleGroupIdentifier(from fields: [String: String]) -> String? {
        fields["pgid"] ?? fields["gid"] ?? fields["tsid"]
    }

    private func appleDisplayName(
        candidateName: String,
        fields: [String: String],
        kind: NoxPresenceDeviceKind
    ) -> String {
        if kind == .homePod, let groupName = fields["gpn"], !groupName.isEmpty {
            return groupName
        }
        return candidateName
    }

    private func appleDeviceId(
        candidateName: String,
        kind: NoxPresenceDeviceKind,
        hostName: String?,
        fields: [String: String],
        groupId: String?
    ) -> String {
        if kind == .homePod, let groupId, !groupId.isEmpty {
            return "apple-\(kind.rawValue)-group-\(normalizedKey(groupId))"
        }
        if let hostName, !hostName.isEmpty {
            return "apple-\(kind.rawValue)-host-\(normalizedKey(hostName))"
        }
        if let deviceId = fields["deviceid"], !deviceId.isEmpty {
            return "apple-\(kind.rawValue)-device-\(normalizedKey(deviceId))"
        }
        return "apple-\(kind.rawValue)-name-\(normalizedKey(candidateName))"
    }

    private func bestDisplayName(
        existing: String?,
        incoming: String,
        kind: NoxPresenceDeviceKind
    ) -> String {
        guard let existing else { return incoming }
        let fallback = "Nearby \(kind.typeLabel)"
        if existing == fallback { return incoming }
        if incoming == fallback { return existing }
        if incoming.count > existing.count { return incoming }
        return existing
    }

    private func mergedMemberNames(existing: NoxDiscoveredNode?, serviceName: String) -> [String] {
        var names = existing?.appleGroupMemberNames ?? []
        if !names.contains(serviceName) {
            names.append(serviceName)
        }
        return names
    }

    private func normalizedKey(_ value: String) -> String {
        value
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
            .prefix(64)
            .description
    }
}

private extension NoxPresenceNodeState {
    var sortRank: Int {
        switch self {
        case .nearby, .pairingRequested, .awaitingApproval: 0
        case .trusted: 1
        case .unavailable: 2
        case .thisDevice: 3
        case .rejected, .error: 4
        }
    }
}

extension BonjourPresenceDiscoveryProvider: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        guard service.type == noxServiceType || appleServiceTypes.contains(service.type) else { return }
        service.delegate = self
        resolving[serviceKey(service)] = service
        service.resolve(withTimeout: 5)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        resolving.removeValue(forKey: serviceKey(service))
        remove(service: service)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        NoxPresenceMeshDiagnostics.log("Presence listen paused")
    }
}

extension BonjourPresenceDiscoveryProvider: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        if sender.type == noxServiceType {
            upsertNoxService(service: sender, hostName: sender.hostName, port: sender.port)
        } else {
            upsertApplePresence(service: sender, hostName: sender.hostName, port: sender.port)
        }
        sender.startMonitoring()
    }

    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        if sender.type == noxServiceType {
            upsertNoxService(service: sender, hostName: sender.hostName, port: sender.port)
        } else {
            upsertApplePresence(service: sender, hostName: sender.hostName, port: sender.port)
        }
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        NoxPresenceMeshDiagnostics.log("Environment resolve incomplete")
    }
}
