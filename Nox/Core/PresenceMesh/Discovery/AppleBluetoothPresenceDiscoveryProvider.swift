import CoreBluetooth
import Foundation

/// Listens for high-confidence Apple Continuity BLE presence.
final class AppleBluetoothPresenceDiscoveryProvider: NSObject, @unchecked Sendable {
    var onNodesChanged: (@Sendable ([NoxDiscoveredNode]) -> Void)?

    private var central: CBCentralManager?
    private var nodes: [String: NoxDiscoveredNode] = [:]
    private let queue = DispatchQueue(label: "dev.nox.mesh.apple-bluetooth")
    private var expiryTask: DispatchWorkItem?
    private var bestDisplayName: String?
    private var deniedLogged = false

    func start() {
        switch CBCentralManager.authorization {
        case .denied, .restricted:
            if !deniedLogged {
                deniedLogged = true
                NoxPresenceMeshDiagnostics.log(
                    "Bluetooth discovery skipped — enable Bluetooth for Nox in System Settings"
                )
            }
            return
        case .allowedAlways, .notDetermined:
            break
        @unknown default:
            return
        }

        if central == nil {
            central = CBCentralManager(delegate: self, queue: queue)
        } else if central?.state == .poweredOn {
            startScanning()
        }
    }

    func stop() {
        expiryTask?.cancel()
        expiryTask = nil
        central?.stopScan()
        nodes.removeAll()
        onNodesChanged?([])
    }

    private func startScanning() {
        guard CBCentralManager.authorization == .allowedAlways else { return }
        central?.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        scheduleExpiry()
        NoxPresenceMeshDiagnostics.log("Presence listening for Apple Continuity signals")
    }

    private func upsertAppleContinuityPresence() {
        let node = NoxDiscoveredNode(
            deviceId: "apple-ble-nearby-iphone",
            deviceName: bestDisplayName ?? "Nearby iPhone",
            protocolVersion: 1,
            publicKeyFingerprint: "",
            presenceToken: "apple-continuity:iPhone",
            pairingPort: 0,
            state: .unavailable,
            lastSeenAt: Date(),
            hostName: nil
        )
        nodes[node.deviceId] = node
        emit()
    }

    private func emit() {
        onNodesChanged?(Array(nodes.values))
    }

    private func scheduleExpiry() {
        expiryTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let cutoff = Date().addingTimeInterval(-90)
            self.nodes = self.nodes.filter { $0.value.lastSeenAt >= cutoff }
            self.emit()
            self.scheduleExpiry()
        }
        expiryTask = task
        queue.asyncAfter(deadline: .now() + 30, execute: task)
    }

    private func hasIOSContinuitySignal(_ advertisementData: [String: Any]) -> Bool {
        guard let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return false
        }
        guard data.count >= 4 else { return false }
        guard data[0] == 0x4c, data[1] == 0x00 else { return false }

        var index = 2
        while index < data.count {
            let type = data[index]
            let lengthIndex = index + 1
            guard lengthIndex < data.count else { return false }
            let length = Int(data[lengthIndex])
            let next = lengthIndex + 1 + length
            guard next <= data.count else { return false }

            if type == 0x10 {
                return true
            }
            index = next
        }

        return false
    }
}

extension AppleBluetoothPresenceDiscoveryProvider: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        default:
            central.stopScan()
            nodes.removeAll()
            emit()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard RSSI.intValue > -88 else { return }
        guard hasIOSContinuitySignal(advertisementData) else { return }
        if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String,
           let cleaned = NoxPresenceCurator.displayEnvironmentName(localName),
           NoxPresenceDeviceKind.confidentlyInfer(from: cleaned) == .iPhone {
            bestDisplayName = cleaned
        }
        upsertAppleContinuityPresence()
    }
}
