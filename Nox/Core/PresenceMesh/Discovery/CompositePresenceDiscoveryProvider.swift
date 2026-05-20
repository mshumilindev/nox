import Foundation

final class CompositePresenceDiscoveryProvider: PresenceDiscoveryProvider, @unchecked Sendable {
    var onNodesChanged: (@Sendable ([NoxDiscoveredNode]) -> Void)?

    private let bonjour = BonjourPresenceDiscoveryProvider()
    private let bluetooth = AppleBluetoothPresenceDiscoveryProvider()
    private let queue = DispatchQueue(label: "dev.nox.mesh.composite-discovery")
    private var bonjourNodes: [NoxDiscoveredNode] = []
    private var bluetoothNodes: [NoxDiscoveredNode] = []
    private var lastSignature = ""

    init() {
        bonjour.onNodesChanged = { [weak self] nodes in
            self?.queue.async {
                self?.bonjourNodes = nodes
                self?.emit()
            }
        }
        bluetooth.onNodesChanged = { [weak self] nodes in
            self?.queue.async {
                self?.bluetoothNodes = nodes
                self?.emit()
            }
        }
    }

    func start(identity: NoxNodeIdentity, port: UInt16, presenceToken: String) throws {
        try bonjour.start(identity: identity, port: port, presenceToken: presenceToken)
    }

    /// Apple Continuity BLE — only while Presence is open (avoids Bluetooth prompt at launch).
    func setAppleBluetoothDiscoveryActive(_ active: Bool) {
        if active {
            bluetooth.start()
        } else {
            bluetooth.stop()
        }
    }

    func stop() {
        bonjour.stop()
        bluetooth.stop()
        queue.async {
            self.bonjourNodes.removeAll()
            self.bluetoothNodes.removeAll()
            self.emit()
        }
    }

    private func emit() {
        var keyed: [String: NoxDiscoveredNode] = [:]
        for node in bonjourNodes + bluetoothNodes {
            keyed[node.deviceId] = node
        }
        let list = collapseAppleGroups(Array(keyed.values)).sorted {
            $0.deviceId.localizedStandardCompare($1.deviceId) == .orderedAscending
        }
        let signature = list
            .map {
                [
                    $0.deviceId,
                    $0.deviceName,
                    $0.state.rawValue,
                    $0.presenceToken,
                    $0.hostName ?? "",
                    "\($0.pairingPort)",
                    $0.appleModel ?? "",
                    $0.appleDeviceIdentifier ?? "",
                    $0.appleGroupIdentifier ?? "",
                    $0.appleGroupName ?? "",
                    $0.appleGroupMemberNames.joined(separator: ","),
                ].joined(separator: "|")
            }
            .joined(separator: "\n")
        guard signature != lastSignature else { return }
        lastSignature = signature
        onNodesChanged?(list)
    }

    private func collapseAppleGroups(_ nodes: [NoxDiscoveredNode]) -> [NoxDiscoveredNode] {
        var grouped: [String: NoxDiscoveredNode] = [:]
        for node in nodes {
            let key = appleGroupCollapseKey(for: node) ?? node.deviceId
            if let existing = grouped[key] {
                grouped[key] = mergedAppleGroup(existing, node)
            } else {
                grouped[key] = node
            }
        }
        return Array(grouped.values)
    }

    private func appleGroupCollapseKey(for node: NoxDiscoveredNode) -> String? {
        guard NoxPresenceCurator.resolvedDeviceKind(for: node) == .homePod else { return nil }
        if let group = node.appleGroupIdentifier, !group.isEmpty {
            return "homepod-group-\(normalizedGroupKey(group))"
        }
        if let groupName = node.appleGroupName, !groupName.isEmpty {
            return "homepod-name-\(normalizedGroupKey(groupName))"
        }
        let normalizedName = normalizedHomePodPairName(node.deviceName)
        return normalizedName.isEmpty ? nil : "homepod-name-\(normalizedGroupKey(normalizedName))"
    }

    private func mergedAppleGroup(_ lhs: NoxDiscoveredNode, _ rhs: NoxDiscoveredNode) -> NoxDiscoveredNode {
        let preferred = preferredGroupBase(lhs, rhs)
        let other = preferred.deviceId == lhs.deviceId ? rhs : lhs
        var merged = preferred
        merged.deviceName = bestGroupName(preferred.deviceName, other.deviceName, groupName: preferred.appleGroupName ?? other.appleGroupName)
        merged.hostName = preferred.hostName ?? other.hostName
        merged.appleModel = preferred.appleModel ?? other.appleModel
        merged.appleDeviceIdentifier = preferred.appleDeviceIdentifier ?? other.appleDeviceIdentifier
        merged.appleGroupIdentifier = preferred.appleGroupIdentifier ?? other.appleGroupIdentifier
        merged.appleGroupName = preferred.appleGroupName ?? other.appleGroupName
        merged.appleDiscoverySource = preferred.appleDiscoverySource?.merged(with: other.appleDiscoverySource) ?? other.appleDiscoverySource
        merged.appleGroupMemberNames = stableUnique(preferred.appleGroupMemberNames + other.appleGroupMemberNames + [preferred.deviceName, other.deviceName])
        merged.lastSeenAt = max(preferred.lastSeenAt, other.lastSeenAt)
        return merged
    }

    private func preferredGroupBase(_ lhs: NoxDiscoveredNode, _ rhs: NoxDiscoveredNode) -> NoxDiscoveredNode {
        if lhs.appleGroupIdentifier == nil, rhs.appleGroupIdentifier != nil { return rhs }
        if lhs.appleGroupName == nil, rhs.appleGroupName != nil { return rhs }
        return lhs.deviceId.localizedStandardCompare(rhs.deviceId) == .orderedAscending ? lhs : rhs
    }

    private func bestGroupName(_ lhs: String, _ rhs: String, groupName: String?) -> String {
        if let groupName, !groupName.isEmpty { return groupName }
        let left = normalizedHomePodPairName(lhs)
        let right = normalizedHomePodPairName(rhs)
        if left == right { return left }
        if lhs.contains("("), !rhs.contains("(") { return rhs }
        if rhs.contains("("), !lhs.contains("(") { return lhs }
        return lhs.count <= rhs.count ? lhs : rhs
    }

    private func normalizedHomePodPairName(_ name: String) -> String {
        name.replacingOccurrences(of: #" \(\d+\)$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedGroupKey(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }

    private func stableUnique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in values where !value.isEmpty {
            let key = normalizedGroupKey(value)
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(value)
        }
        return result
    }
}
