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
        let list = Array(keyed.values).sorted {
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
}
