import XCTest
@testable import Nox

final class NoxDeviceArtworkResolverTests: XCTestCase {
    func testURLBuilderUsesLittlebyteAppleDeviceImagesRawPaths() {
        let urls = DeviceArtworkURLBuilder.imageURLs(deviceKey: "Mac14,2", colorKey: "Space Gray")
        XCTAssertEqual(urls[0].absoluteString, "https://raw.githubusercontent.com/littlebyteorg/apple-device-images/main/device/Mac14,2/Space%20Gray_dark.png")
        XCTAssertEqual(urls[1].absoluteString, "https://raw.githubusercontent.com/littlebyteorg/apple-device-images/main/device/Mac14,2/Space%20Gray.png")
        XCTAssertEqual(urls[2].absoluteString, "https://raw.githubusercontent.com/littlebyteorg/apple-device-images/main/device/Mac14,2.png")
        XCTAssertEqual(urls[3].absoluteString, "https://raw.githubusercontent.com/littlebyteorg/apple-device-images/main/device-lowres/Mac14,2.png")
    }

    func testAirplaySourceUsesGenericArtworkIdentity() {
        let node = NoxDiscoveredNode(
            deviceId: "apple-iphone-airplay",
            deviceName: "Kitchen iPhone",
            protocolVersion: 1,
            publicKeyFingerprint: "",
            presenceToken: "apple-presence:iPhone",
            pairingPort: 7000,
            state: .unavailable,
            lastSeenAt: Date(),
            appleDiscoverySource: .airplay
        )
        let identity = NoxPresenceHardwareIdentityResolver.hardwareIdentity(for: node)
        XCTAssertEqual(identity.confidence, .generic)
        XCTAssertFalse(identity.showsConcreteAppleDevice)
    }

    func testAirplayHomePodUsesExactArtworkIdentityWhenModelIsPresent() {
        let node = NoxDiscoveredNode(
            deviceId: "apple-homePod-group-living-room",
            deviceName: "Living room",
            protocolVersion: 1,
            publicKeyFingerprint: "",
            presenceToken: "apple-presence:homePod",
            pairingPort: 7000,
            state: .unavailable,
            lastSeenAt: Date(),
            appleModel: "AudioAccessory1,1",
            appleDiscoverySource: .airplay
        )
        let identity = NoxPresenceHardwareIdentityResolver.hardwareIdentity(for: node)
        XCTAssertEqual(identity.confidence, .exact)
        XCTAssertEqual(identity.deviceKey, "AudioAccessory1,1")
        XCTAssertEqual(identity.fallbackKind, .homePod)
        XCTAssertTrue(identity.showsConcreteAppleDevice)
    }

    func testAirplayAppleTVUsesExactArtworkIdentityWhenModelIsPresent() {
        let node = NoxDiscoveredNode(
            deviceId: "apple-appleTV-host-living-room",
            deviceName: "Вітальня",
            protocolVersion: 1,
            publicKeyFingerprint: "",
            presenceToken: "apple-presence:appleTV",
            pairingPort: 7000,
            state: .unavailable,
            lastSeenAt: Date(),
            appleModel: "AppleTV11,1",
            appleDiscoverySource: .airplay
        )
        let identity = NoxPresenceHardwareIdentityResolver.hardwareIdentity(for: node)
        XCTAssertEqual(identity.confidence, .exact)
        XCTAssertEqual(identity.deviceKey, "AppleTV11,1")
        XCTAssertEqual(identity.fallbackKind, .appleTV)
        XCTAssertTrue(identity.showsConcreteAppleDevice)
    }

    func testTrustedDeviceInfoUsesExactKey() {
        let node = NoxDiscoveredNode(
            deviceId: "apple-iphone-info",
            deviceName: "Nearby iPhone",
            protocolVersion: 1,
            publicKeyFingerprint: "",
            presenceToken: "apple-presence:iPhone",
            pairingPort: 0,
            state: .unavailable,
            lastSeenAt: Date(),
            appleDeviceIdentifier: "iPhone14,2",
            appleDiscoverySource: .deviceInfo
        )
        let identity = NoxPresenceHardwareIdentityResolver.hardwareIdentity(for: node)
        XCTAssertEqual(identity.confidence, .exact)
        XCTAssertEqual(identity.deviceKey, "iPhone14,2")
        XCTAssertTrue(identity.showsConcreteAppleDevice)
    }

    func testAirplayIMacModelUsesExactIMacArtworkIdentity() {
        let node = NoxDiscoveredNode(
            deviceId: "apple-iMac-host-imac-mykola",
            deviceName: "iMac — Mykola",
            protocolVersion: 1,
            publicKeyFingerprint: "",
            presenceToken: "apple-presence:iMac",
            pairingPort: 7000,
            state: .unavailable,
            lastSeenAt: Date(),
            appleModel: "iMac20,1",
            appleDiscoverySource: .airplay
        )
        let identity = NoxPresenceHardwareIdentityResolver.hardwareIdentity(for: node)
        XCTAssertEqual(identity.confidence, .exact)
        XCTAssertEqual(identity.deviceKey, "iMac20,1")
        XCTAssertEqual(identity.fallbackKind, .iMac)
        XCTAssertTrue(identity.showsConcreteAppleDevice)
    }

    func testAirplayReceiverNameBeatsConflictingAppleTVModel() {
        let node = NoxDiscoveredNode(
            deviceId: "apple-appleTV-host-imac-mykola",
            deviceName: "iMac — Mykola",
            protocolVersion: 1,
            publicKeyFingerprint: "",
            presenceToken: "apple-presence:appleTV",
            pairingPort: 7000,
            state: .unavailable,
            lastSeenAt: Date(),
            appleModel: "AppleTV11,1",
            appleDiscoverySource: .airplay
        )
        let kind = NoxPresenceCurator.resolvedDeviceKind(for: node)
        let identity = NoxPresenceHardwareIdentityResolver.hardwareIdentity(for: node, expectedKind: kind)
        XCTAssertEqual(kind, .iMac)
        XCTAssertEqual(identity.confidence, .family)
        XCTAssertEqual(identity.deviceKey, NoxPresenceFamilyArtwork.imageKey(for: .iMac))
        XCTAssertEqual(identity.fallbackKind, .iMac)
        XCTAssertTrue(identity.showsConcreteAppleDevice)
    }

    func testDeviceInfoReceiverNameBeatsConflictingAppleTVModel() {
        let node = NoxDiscoveredNode(
            deviceId: "apple-appleTV-host-imac-mykola",
            deviceName: "iMac — Mykola",
            protocolVersion: 1,
            publicKeyFingerprint: "",
            presenceToken: "apple-presence:appleTV",
            pairingPort: 7000,
            state: .unavailable,
            lastSeenAt: Date(),
            appleModel: "AppleTV11,1",
            appleDiscoverySource: .deviceInfo
        )
        let kind = NoxPresenceCurator.resolvedDeviceKind(for: node)
        let identity = NoxPresenceHardwareIdentityResolver.hardwareIdentity(for: node, expectedKind: kind)
        XCTAssertEqual(kind, .iMac)
        XCTAssertEqual(identity.confidence, .family)
        XCTAssertEqual(identity.deviceKey, NoxPresenceFamilyArtwork.imageKey(for: .iMac))
        XCTAssertEqual(identity.fallbackKind, .iMac)
        XCTAssertTrue(identity.showsConcreteAppleDevice)
    }
}
