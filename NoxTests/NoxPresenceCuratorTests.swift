import XCTest
@testable import Nox

@MainActor
final class NoxPresenceCuratorTests: XCTestCase {
    func testRejectsMediaPlayerNames() {
        XCTAssertNil(NoxPresenceCurator.displayEnvironmentName("Elmedia Video Player iMac"))
        XCTAssertNil(NoxPresenceCurator.displayEnvironmentName("Living Room TV"))
    }

    func testAcceptsAppleHostNames() {
        XCTAssertEqual(
            NoxPresenceCurator.displayEnvironmentName("Mykola's MacBook Pro"),
            "Mykola's MacBook Pro"
        )
    }

    func testRejectsNonNoxMeshNodes() {
        let node = NoxDiscoveredNode(
            deviceId: "apple-imac",
            deviceName: "iMac",
            protocolVersion: 1,
            publicKeyFingerprint: "",
            presenceToken: "_airplay._tcp.",
            pairingPort: 7000,
            state: .unavailable,
            lastSeenAt: Date()
        )
        XCTAssertFalse(NoxPresenceCurator.isPresentableNoxEnvironment(node))
    }

    func testAcceptsValidNoxEnvironment() {
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
        XCTAssertTrue(NoxPresenceCurator.isPresentableNoxEnvironment(node))
    }
}
