import Foundation

nonisolated struct NoxNodeIdentity: Codable, Equatable, Sendable, Identifiable {
    static let currentProtocolVersion = 1

    let systemId: String
    let deviceId: String
    var deviceName: String
    let protocolVersion: Int
    let publicKeyFingerprint: String
    let createdAt: Date

    var id: String { deviceId }

    init(
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

nonisolated struct NoxNodeIdentityDocument: Codable, Sendable {
    let identity: NoxNodeIdentity
    let publicKeyBase64: String
}
