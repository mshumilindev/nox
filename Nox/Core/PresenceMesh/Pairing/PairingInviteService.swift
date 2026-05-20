import Foundation

nonisolated struct NoxPairingInvite: Codable, Sendable, Equatable {
    static let fileType = "nox_pairing_invite"

    let type: String
    let systemId: String
    let primaryDeviceId: String
    let primaryDeviceName: String
    let createdAt: String
    let expiresAt: String
    let localDiscoveryService: String
    let inviteToken: String
    let signature: String
    let publicKeyBase64: String
    let pairingPort: Int
    let protocolVersion: Int
}

/// Generates signed `.noxpair` invites and deep-link payloads.
nonisolated final class PairingInviteService: @unchecked Sendable {
    private var usedTokens: Set<String> = []
    private let lock = NSLock()

    func makeInvite(
        identity: NoxNodeIdentity,
        publicKeyBase64: String,
        pairingPort: Int,
        privateKeyData: Data,
        ttl: TimeInterval = 3600
    ) throws -> NoxPairingInvite {
        let token = UUID().uuidString.lowercased()
        let created = Date()
        let expires = created.addingTimeInterval(ttl)
        let formatter = ISO8601DateFormatter()
        let createdAt = formatter.string(from: created)
        let expiresAt = formatter.string(from: expires)

        var message = NoxMeshMessage(
            type: .pairingRequest,
            protocolVersion: identity.protocolVersion,
            fromDeviceId: identity.deviceId,
            fromDeviceName: identity.deviceName,
            nonce: token,
            timestamp: createdAt,
            signature: nil,
            systemId: identity.systemId,
            publicKeyFingerprint: identity.publicKeyFingerprint,
            publicKeyBase64: publicKeyBase64,
            pairingPort: pairingPort,
            inviteToken: token
        )
        let payload = message.signingPayload(extra: ["inviteToken": token])
        let signature = try NoxMeshCrypto.sign(payload: payload, privateKeyData: privateKeyData)
        message.signature = signature

        return NoxPairingInvite(
            type: NoxPairingInvite.fileType,
            systemId: identity.systemId,
            primaryDeviceId: identity.deviceId,
            primaryDeviceName: identity.deviceName,
            createdAt: createdAt,
            expiresAt: expiresAt,
            localDiscoveryService: "_nox._tcp",
            inviteToken: token,
            signature: signature,
            publicKeyBase64: publicKeyBase64,
            pairingPort: pairingPort,
            protocolVersion: identity.protocolVersion
        )
    }

    func validate(_ invite: NoxPairingInvite) throws {
        guard invite.type == NoxPairingInvite.fileType else {
            throw NoxMeshError.verificationFailed("Invalid invite type")
        }
        guard let expires = ISO8601DateFormatter().date(from: invite.expiresAt),
              expires > Date() else {
            throw NoxMeshError.inviteExpired
        }
        lock.lock()
        let used = usedTokens.contains(invite.inviteToken)
        if !used { usedTokens.insert(invite.inviteToken) }
        lock.unlock()
        if used { throw NoxMeshError.inviteAlreadyUsed }

        let message = NoxMeshMessage(
            type: .pairingRequest,
            protocolVersion: invite.protocolVersion,
            fromDeviceId: invite.primaryDeviceId,
            fromDeviceName: invite.primaryDeviceName,
            nonce: invite.inviteToken,
            timestamp: invite.createdAt,
            signature: invite.signature,
            systemId: invite.systemId,
            publicKeyFingerprint: nil,
            publicKeyBase64: invite.publicKeyBase64,
            inviteToken: invite.inviteToken
        )
        try PairingMessageVerifier().verify(
            message,
            publicKeyBase64: invite.publicKeyBase64,
            trustEstablishing: true
        )
    }

    func encodeFile(_ invite: NoxPairingInvite) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(invite)
    }

    func decodeFile(_ data: Data) throws -> NoxPairingInvite {
        try JSONDecoder().decode(NoxPairingInvite.self, from: data)
    }

    func sharePlainText(_ invite: NoxPairingInvite) -> String {
        """
        Nox pairing invite from \(invite.primaryDeviceName).
        Install or run Nox on the target Mac, then open this pairing invite:
        nox://pair?systemId=\(invite.systemId)&invite=\(invite.inviteToken)&deviceId=\(invite.primaryDeviceId)
        """
    }
}
