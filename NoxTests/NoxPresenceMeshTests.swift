import CryptoKit
import XCTest
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
@testable import Nox

@MainActor
final class NoxPresenceMeshMacTests: XCTestCase {
    func testPairingInviteEncodeDecode() throws {
        let identity = NoxNodeIdentity(
            systemId: "sys",
            deviceId: "dev",
            deviceName: "Test Mac",
            publicKeyFingerprint: "abcd1234"
        )
        let privateKey = Curve25519.Signing.PrivateKey()
        let service = PairingInviteService()
        let invite = try service.makeInvite(
            identity: identity,
            publicKeyBase64: privateKey.publicKey.rawRepresentation.base64EncodedString(),
            pairingPort: 9121,
            privateKeyData: privateKey.rawRepresentation,
            ttl: 600
        )
        let data = try service.encodeFile(invite)
        let decoded = try service.decodeFile(data)
        XCTAssertEqual(decoded.primaryDeviceId, identity.deviceId)
        XCTAssertEqual(decoded.type, NoxPairingInvite.fileType)
        XCTAssertFalse(decoded.signature.isEmpty)
    }
}
