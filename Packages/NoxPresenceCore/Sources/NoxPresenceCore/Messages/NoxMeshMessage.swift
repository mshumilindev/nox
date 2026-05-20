import Foundation
import NoxCore

public nonisolated enum NoxMeshMessageType: String, Codable, Sendable {
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
public nonisolated struct NoxMeshMessage: Codable, Sendable, Equatable {
    public let type: NoxMeshMessageType
    public let protocolVersion: Int
    public let fromDeviceId: String
    public let fromDeviceName: String
    public let nonce: String
    public let timestamp: String
    public var signature: String?
    public var systemId: String?
    public var publicKeyFingerprint: String?
    public var publicKeyBase64: String?
    public var pairingPort: Int?
    public var challenge: String?
    public var response: String?
    public var inviteToken: String?
    public var message: String?

    public init(
        type: NoxMeshMessageType,
        protocolVersion: Int,
        fromDeviceId: String,
        fromDeviceName: String,
        nonce: String,
        timestamp: String,
        signature: String? = nil,
        systemId: String? = nil,
        publicKeyFingerprint: String? = nil,
        publicKeyBase64: String? = nil,
        pairingPort: Int? = nil,
        challenge: String? = nil,
        response: String? = nil,
        inviteToken: String? = nil,
        message: String? = nil
    ) {
        self.type = type
        self.protocolVersion = protocolVersion
        self.fromDeviceId = fromDeviceId
        self.fromDeviceName = fromDeviceName
        self.nonce = nonce
        self.timestamp = timestamp
        self.signature = signature
        self.systemId = systemId
        self.publicKeyFingerprint = publicKeyFingerprint
        self.publicKeyBase64 = publicKeyBase64
        self.pairingPort = pairingPort
        self.challenge = challenge
        self.response = response
        self.inviteToken = inviteToken
        self.message = message
    }

    public var requiresSignature: Bool {
        switch type {
        case .pairingRequest, .pairingChallenge, .pairingResponse,
             .pairingApproved, .pairingRejected, .trustEstablished:
            return true
        default:
            return false
        }
    }

    public func signingPayload(extra: [String: String] = [:]) -> Data {
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

nonisolated public enum NoxPresenceNodeState: String, Codable, Sendable, Equatable {
    case thisDevice
    case nearby
    case pairingRequested
    case awaitingApproval
    case trusted
    case unavailable
    case rejected
    case error
}

public nonisolated struct NoxDiscoveredNode: Identifiable, Equatable, Sendable {
    public let deviceId: String
    public var deviceName: String
    public let protocolVersion: Int
    public let publicKeyFingerprint: String
    public let presenceToken: String
    public let pairingPort: Int
    public var state: NoxPresenceNodeState
    public var lastSeenAt: Date
    public var systemId: String?
    public var publicKeyBase64: String?
    public var hostName: String?
    public var appleModel: String?
    public var appleDeviceIdentifier: String?
    public var appleGroupIdentifier: String?
    public var appleGroupName: String?
    public var appleGroupMemberNames: [String]
    public var appleDiscoverySource: NoxAppleDiscoverySource?

    public var id: String { deviceId }

    public init(
        deviceId: String,
        deviceName: String,
        protocolVersion: Int,
        publicKeyFingerprint: String,
        presenceToken: String,
        pairingPort: Int,
        state: NoxPresenceNodeState,
        lastSeenAt: Date,
        systemId: String? = nil,
        publicKeyBase64: String? = nil,
        hostName: String? = nil,
        appleModel: String? = nil,
        appleDeviceIdentifier: String? = nil,
        appleGroupIdentifier: String? = nil,
        appleGroupName: String? = nil,
        appleGroupMemberNames: [String] = [],
        appleDiscoverySource: NoxAppleDiscoverySource? = nil
    ) {
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.protocolVersion = protocolVersion
        self.publicKeyFingerprint = publicKeyFingerprint
        self.presenceToken = presenceToken
        self.pairingPort = pairingPort
        self.state = state
        self.lastSeenAt = lastSeenAt
        self.systemId = systemId
        self.publicKeyBase64 = publicKeyBase64
        self.hostName = hostName
        self.appleModel = appleModel
        self.appleDeviceIdentifier = appleDeviceIdentifier
        self.appleGroupIdentifier = appleGroupIdentifier
        self.appleGroupName = appleGroupName
        self.appleGroupMemberNames = appleGroupMemberNames
        self.appleDiscoverySource = appleDiscoverySource
    }

    public var isTrustedCandidate: Bool {
        state == .nearby || state == .pairingRequested || state == .awaitingApproval
    }
}
