import CryptoKit
import Foundation

public nonisolated enum NoxMeshCrypto {
    public static func fingerprint(publicKey: Curve25519.Signing.PublicKey) -> String {
        let digest = SHA256.hash(data: publicKey.rawRepresentation)
        return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    public static func sign(payload: Data, privateKeyData: Data) throws -> String {
        let key = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
        let sig = try key.signature(for: payload)
        return sig.base64EncodedString()
    }

    public static func verify(payload: Data, signatureBase64: String, publicKeyBase64: String) -> Bool {
        guard let sigData = Data(base64Encoded: signatureBase64),
              let keyData = Data(base64Encoded: publicKeyBase64),
              let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData) else {
            return false
        }
        return publicKey.isValidSignature(sigData, for: payload)
    }

    public static func canonicalPayload(
        type: String,
        protocolVersion: Int,
        fromDeviceId: String,
        fromDeviceName: String,
        nonce: String,
        timestamp: String,
        extra: [String: String] = [:]
    ) -> Data {
        var parts = [
            "type=\(type)",
            "protocolVersion=\(protocolVersion)",
            "fromDeviceId=\(fromDeviceId)",
            "fromDeviceName=\(fromDeviceName)",
            "nonce=\(nonce)",
            "timestamp=\(timestamp)",
        ]
        for key in extra.keys.sorted() {
            if let value = extra[key] {
                parts.append("\(key)=\(value)")
            }
        }
        return Data(parts.joined(separator: "&").utf8)
    }
}
