import Foundation
import NoxPresenceCore
import Testing

struct NoxPresenceCuratorPackageTests {

    @Test func rejectsMediaPlayerNames() {
        #expect(NoxPresenceCurator.displayEnvironmentName("Elmedia Video Player iMac") == nil)
        #expect(NoxPresenceCurator.displayEnvironmentName("Living Room TV") == nil)
    }

    @Test func acceptsAppleHostNames() {
        #expect(
            NoxPresenceCurator.displayEnvironmentName("Mykola's MacBook Pro")
                == "Mykola's MacBook Pro"
        )
    }

    @Test func rejectsInvalidMeshDeviceIds() {
        let node = NoxDiscoveredNode(
            deviceId: "not-a-valid-uuid",
            deviceName: "Studio MacBook Pro",
            protocolVersion: 1,
            publicKeyFingerprint: "a1b2c3d4",
            presenceToken: "tok",
            pairingPort: 9121,
            state: .nearby,
            lastSeenAt: Date()
        )
        #expect(!NoxPresenceCurator.isPresentableNoxEnvironment(node))
    }

    @Test func acceptsValidNoxEnvironment() {
        let node = NoxDiscoveredNode(
            deviceId: UUID().uuidString.lowercased(),
            deviceName: "Studio MacBook Pro",
            protocolVersion: 1,
            publicKeyFingerprint: "a1b2c3d4",
            presenceToken: "tok",
            pairingPort: 9121,
            state: .nearby,
            lastSeenAt: Date()
        )
        #expect(NoxPresenceCurator.isPresentableNoxEnvironment(node))
    }
}
