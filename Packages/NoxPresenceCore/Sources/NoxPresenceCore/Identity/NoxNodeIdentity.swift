import Foundation

nonisolated public struct NoxNodeIdentity: Codable, Equatable, Sendable, Identifiable {
    public static let currentProtocolVersion = 1

    public let systemId: String
    public let deviceId: String
    public var deviceName: String
    public let protocolVersion: Int
    public let publicKeyFingerprint: String
    public let createdAt: Date

    public var id: String { deviceId }

    public init(
        systemId: String,
        deviceId: String,
        deviceName: String,
        protocolVersion: Int = NoxNodeIdentity.currentProtocolVersion,
        publicKeyFingerprint: String,
        createdAt: Date = Date()
    ) {
        self.systemId = systemId
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.protocolVersion = protocolVersion
        self.publicKeyFingerprint = publicKeyFingerprint
        self.createdAt = createdAt
    }
}

public nonisolated struct NoxNodeIdentityDocument: Codable, Sendable {
    public let identity: NoxNodeIdentity
    public let publicKeyBase64: String

    public init(identity: NoxNodeIdentity, publicKeyBase64: String) {
        self.identity = identity
        self.publicKeyBase64 = publicKeyBase64
    }
}
