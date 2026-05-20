import Foundation

nonisolated enum NoxMeshMessageType: String, Codable, Sendable {
    case presenceHello = "presence_hello"
    case pairingRequest = "pairing_request"
    case pairingChallenge = "pairing_challenge"
    case pairingResponse = "pairing_response"
    case pairingApproved = "pairing_approved"
    case pairingRejected = "pairing_rejected"
    case trustEstablished = "trust_established"
    case testPing = "test_ping"
    case testPong = "test_pong"
    case testPulse = "test_pulse"
}

/// Versioned LAN mesh envelope — signed for trust-establishing types.
nonisolated struct NoxMeshMessage: Codable, Sendable, Equatable {
    let type: NoxMeshMessageType
    let protocolVersion: Int
    let fromDeviceId: String
    let fromDeviceName: String
    let nonce: String
    let timestamp: String
    var signature: String?
    var systemId: String?
    var publicKeyFingerprint: String?
    var publicKeyBase64: String?
    var pairingPort: Int?
    var challenge: String?
    var response: String?
    var inviteToken: String?
    var message: String?

    var requiresSignature: Bool {
        switch type {
        case .pairingRequest, .pairingChallenge, .pairingResponse,
             .pairingApproved, .pairingRejected, .trustEstablished:
            return true
        default:
            return false
        }
    }

    func signingPayload(extra: [String: String] = [:]) -> Data {
        var merged = extra
        if let systemId { merged["systemId"] = systemId }
        if let publicKeyFingerprint { merged["publicKeyFingerprint"] = publicKeyFingerprint }
        if let challenge { merged["challenge"] = challenge }
        if let response { merged["response"] = response }
        if let inviteToken { merged["inviteToken"] = inviteToken }
        return NoxMeshCrypto.canonicalPayload(
            type: type.rawValue,
            protocolVersion: protocolVersion,
            fromDeviceId: fromDeviceId,
            fromDeviceName: fromDeviceName,
            nonce: nonce,
            timestamp: timestamp,
            extra: merged
        )
    }
}

nonisolated enum NoxPresenceNodeState: String, Codable, Sendable, Equatable {
    case thisDevice
    case nearby
    case pairingRequested
    case awaitingApproval
    case trusted
    case unavailable
    case rejected
    case error
}

nonisolated struct NoxDiscoveredNode: Identifiable, Equatable, Sendable {
    let deviceId: String
    var deviceName: String
    let protocolVersion: Int
    let publicKeyFingerprint: String
    let presenceToken: String
    let pairingPort: Int
    var state: NoxPresenceNodeState
    var lastSeenAt: Date
    var systemId: String?
    var publicKeyBase64: String?
    var hostName: String?
    var appleModel: String?
    var appleDeviceIdentifier: String?
    var appleGroupIdentifier: String?
    var appleGroupName: String?
    var appleGroupMemberNames: [String] = []
    var appleDiscoverySource: NoxAppleDiscoverySource?

    var id: String { deviceId }

    var isTrustedCandidate: Bool {
        state == .nearby || state == .pairingRequested || state == .awaitingApproval
    }
}
