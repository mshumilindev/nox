import CryptoKit
import Foundation

/// Generates and persists local node identity under the active mesh profile folder.
final class LocalIdentityProvider: IdentityProvider, @unchecked Sendable {
    private let profile: NoxMeshProfile
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cached: NoxNodeIdentity?
    private let lock = NSLock()

    init(profile: NoxMeshProfile = NoxMeshRuntime.profile) {
        self.profile = profile
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    private var identityURL: URL {
        NoxPersistencePaths.meshIdentityDirectory.appendingPathComponent("node_identity.json")
    }

    func currentIdentity() -> NoxNodeIdentity? {
        lock.lock()
        defer { lock.unlock() }
        return cached
    }

    func loadOrCreateIdentity() throws -> NoxNodeIdentity {
        lock.lock()
        if let cached { lock.unlock(); return cached }
        lock.unlock()

        NoxPersistencePaths.ensureDirectory(at: NoxPersistencePaths.meshIdentityDirectory)
        if FileManager.default.fileExists(atPath: identityURL.path),
           let data = try? Data(contentsOf: identityURL),
           let doc = try? decoder.decode(NoxNodeIdentityDocument.self, from: data) {
            lock.lock()
            cached = doc.identity
            lock.unlock()
            return doc.identity
        }

        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        try NoxIdentityKeychain.savePrivateKey(privateKey.rawRepresentation, profile: profile)

        let fingerprint = NoxMeshCrypto.fingerprint(publicKey: publicKey)
        let identity = NoxNodeIdentity(
            systemId: UUID().uuidString.lowercased(),
            deviceId: UUID().uuidString.lowercased(),
            deviceName: NoxPresenceCurator.sanitizedHostName() ?? "Mac",
            publicKeyFingerprint: fingerprint
        )
        let doc = NoxNodeIdentityDocument(
            identity: identity,
            publicKeyBase64: publicKey.rawRepresentation.base64EncodedString()
        )
        let data = try encoder.encode(doc)
        try data.write(to: identityURL, options: .atomic)

        lock.lock()
        cached = identity
        lock.unlock()
        NoxPresenceMeshDiagnostics.log("Identity created for \(identity.deviceName) [\(profile.displayName)]")
        return identity
    }

    func resetIdentity() throws -> NoxNodeIdentity {
        NoxIdentityKeychain.deletePrivateKey(profile: profile)
        try? FileManager.default.removeItem(at: identityURL)
        lock.lock()
        cached = nil
        lock.unlock()
        return try loadOrCreateIdentity()
    }

    func signingPrivateKey() throws -> Data {
        guard let data = try NoxIdentityKeychain.loadPrivateKey(profile: profile) else {
            throw NoxMeshError.identityUnavailable
        }
        return data
    }

    func publicKey() throws -> Curve25519.Signing.PublicKey {
        guard FileManager.default.fileExists(atPath: identityURL.path),
              let raw = try? Data(contentsOf: identityURL),
              let doc = try? decoder.decode(NoxNodeIdentityDocument.self, from: raw),
              let keyData = Data(base64Encoded: doc.publicKeyBase64) else {
            throw NoxMeshError.identityUnavailable
        }
        return try Curve25519.Signing.PublicKey(rawRepresentation: keyData)
    }
}

nonisolated enum NoxMeshCrypto {
    static func fingerprint(publicKey: Curve25519.Signing.PublicKey) -> String {
        let digest = SHA256.hash(data: publicKey.rawRepresentation)
        return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    static func sign(payload: Data, privateKeyData: Data) throws -> String {
        let key = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
        let sig = try key.signature(for: payload)
        return sig.base64EncodedString()
    }

    static func verify(payload: Data, signatureBase64: String, publicKeyBase64: String) -> Bool {
        guard let sigData = Data(base64Encoded: signatureBase64),
              let keyData = Data(base64Encoded: publicKeyBase64),
              let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData) else {
            return false
        }
        return publicKey.isValidSignature(sigData, for: payload)
    }

    static func canonicalPayload(
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
