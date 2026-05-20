import Foundation

/// Rejects stale timestamps, replayed nonces, and invalid signatures.
nonisolated final class PairingMessageVerifier: @unchecked Sendable {
    private let maxSkew: TimeInterval = 120
    private let nonceTTL: TimeInterval = 600
    private var usedNonces: [String: Date] = [:]
    private let lock = NSLock()

    func verify(
        _ message: NoxMeshMessage,
        publicKeyBase64: String?,
        trustEstablishing: Bool
    ) throws {
        guard let instant = ISO8601DateFormatter().date(from: message.timestamp) else {
            throw NoxMeshError.verificationFailed("Invalid timestamp format")
        }
        let skew = abs(instant.timeIntervalSinceNow)
        if skew > maxSkew {
            NoxPresenceMeshDiagnostics.log("Stale message rejected from \(message.fromDeviceId)")
            throw NoxMeshError.staleMessage
        }

        try assertFreshNonce(message.nonce)

        if message.requiresSignature || trustEstablishing {
            guard let signature = message.signature, !signature.isEmpty else {
                throw NoxMeshError.verificationFailed("Missing signature")
            }
            guard let key = publicKeyBase64 ?? message.publicKeyBase64 else {
                throw NoxMeshError.verificationFailed("Missing public key")
            }
            var extra: [String: String] = [:]
            if let systemId = message.systemId { extra["systemId"] = systemId }
            if let fp = message.publicKeyFingerprint { extra["publicKeyFingerprint"] = fp }
            if let challenge = message.challenge { extra["challenge"] = challenge }
            if let response = message.response { extra["response"] = response }
            if let inviteToken = message.inviteToken { extra["inviteToken"] = inviteToken }
            let payload = message.signingPayload(extra: extra)
            guard NoxMeshCrypto.verify(payload: payload, signatureBase64: signature, publicKeyBase64: key) else {
                NoxPresenceMeshDiagnostics.log("Signature failed for \(message.type.rawValue)")
                throw NoxMeshError.verificationFailed("Invalid signature")
            }
        }
    }

    private func assertFreshNonce(_ nonce: String) throws {
        lock.lock()
        defer { lock.unlock() }
        pruneNoncesLocked()
        if usedNonces[nonce] != nil {
            NoxPresenceMeshDiagnostics.log("Replayed nonce rejected")
            throw NoxMeshError.replayedNonce
        }
        usedNonces[nonce] = Date()
    }

    private func pruneNoncesLocked() {
        let cutoff = Date().addingTimeInterval(-nonceTTL)
        usedNonces = usedNonces.filter { $0.value > cutoff }
    }

    func reset() {
        lock.lock()
        usedNonces.removeAll()
        lock.unlock()
    }
}
