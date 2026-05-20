import CryptoKit
import Foundation
import NoxPresenceCore
import Testing

struct NoxMeshProfilePackageTests {

    @Test func meshProfilePortsAreDistinct() {
        #expect(NoxMeshProfile(name: "node-a").meshPort == 9121)
        #expect(NoxMeshProfile(name: "node-b").meshPort == 9122)
        #expect(NoxMeshProfile(name: "node-a").meshPort != NoxMeshProfile(name: "node-b").meshPort)
    }
}

struct NoxMeshCryptoPackageTests {

    @Test func canonicalPayloadSigningRoundTrip() throws {
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
        #expect(
            NoxMeshCrypto.verify(
                payload: payload,
                signatureBase64: signature,
                publicKeyBase64: publicKey.rawRepresentation.base64EncodedString()
            )
        )
    }
}

struct NoxPairingMessageVerifierPackageTests {

    @Test func rejectsReplayedNonce() throws {
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
            Issue.record("Expected replayed nonce")
        } catch let error as NoxMeshError {
            #expect(error == .replayedNonce)
        }
    }
}
