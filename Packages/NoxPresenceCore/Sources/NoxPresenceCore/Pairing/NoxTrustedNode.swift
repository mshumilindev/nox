import Foundation

public nonisolated struct NoxTrustedNode: Codable, Equatable, Sendable, Identifiable {
    public let trustedNodeId: String
    public var trustedDeviceName: String
    public let publicKeyFingerprint: String
    public let publicKeyBase64: String
    public let trustCreatedAt: Date
    public var lastSeenAt: Date
    public let systemId: String
    public let protocolVersion: Int
    public var lastHost: String?
    public var lastPairingPort: Int?

    public var id: String { trustedNodeId }

    public init(
        trustedNodeId: String,
        trustedDeviceName: String,
        publicKeyFingerprint: String,
        publicKeyBase64: String,
        trustCreatedAt: Date,
        lastSeenAt: Date,
        systemId: String,
        protocolVersion: Int,
        lastHost: String? = nil,
        lastPairingPort: Int? = nil
    ) {
        self.trustedNodeId = trustedNodeId
        self.trustedDeviceName = trustedDeviceName
        self.publicKeyFingerprint = publicKeyFingerprint
        self.publicKeyBase64 = publicKeyBase64
        self.trustCreatedAt = trustCreatedAt
        self.lastSeenAt = lastSeenAt
        self.systemId = systemId
        self.protocolVersion = protocolVersion
        self.lastHost = lastHost
        self.lastPairingPort = lastPairingPort
    }
}
