import CryptoKit
import XCTest
@testable import Nox

@MainActor
final class NoxPresenceMeshTests: XCTestCase {
    func testMeshProfilePortsAreDistinct() {
        XCTAssertEqual(NoxMeshProfile(name: "node-a").meshPort, 9121)
        XCTAssertEqual(NoxMeshProfile(name: "node-b").meshPort, 9122)
        XCTAssertNotEqual(NoxMeshProfile(name: "node-a").meshPort, NoxMeshProfile(name: "node-b").meshPort)
    }

    func testCanonicalPayloadSigningRoundTrip() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        let payload = NoxMeshCrypto.canonicalPayload(
            type: "pairing_request",
            protocolVersion: 1,
            fromDeviceId: "device-a",
            fromDeviceName: "Mac A",
            nonce: "nonce-1",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            extra: ["inviteToken": "tok"]
        )
        let signature = try NoxMeshCrypto.sign(
            payload: payload,
            privateKeyData: privateKey.rawRepresentation
        )
        XCTAssertTrue(
            NoxMeshCrypto.verify(
                payload: payload,
                signatureBase64: signature,
                publicKeyBase64: publicKey.rawRepresentation.base64EncodedString()
            )
        )
    }

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

    func testPairingMessageVerifierRejectsReplayedNonce() throws {
        let verifier = PairingMessageVerifier()
        let privateKey = Curve25519.Signing.PrivateKey()
        let keyB64 = privateKey.publicKey.rawRepresentation.base64EncodedString()
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let payload = NoxMeshCrypto.canonicalPayload(
            type: NoxMeshMessageType.testPing.rawValue,
            protocolVersion: 1,
            fromDeviceId: "d1",
            fromDeviceName: "A",
            nonce: "same-nonce",
            timestamp: timestamp
        )
        let signature = try NoxMeshCrypto.sign(
            payload: payload,
            privateKeyData: privateKey.rawRepresentation
        )
        let message = NoxMeshMessage(
            type: .testPing,
            protocolVersion: 1,
            fromDeviceId: "d1",
            fromDeviceName: "A",
            nonce: "same-nonce",
            timestamp: timestamp,
            signature: signature,
            publicKeyBase64: keyB64
        )
        try verifier.verify(message, publicKeyBase64: keyB64, trustEstablishing: false)
        do {
            try verifier.verify(message, publicKeyBase64: keyB64, trustEstablishing: false)
            XCTFail("Expected replayed nonce")
        } catch let error as NoxMeshError {
            XCTAssertEqual(error, .replayedNonce)
        }
    }
}
