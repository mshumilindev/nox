import Foundation

nonisolated struct NoxTrustedNode: Codable, Equatable, Sendable, Identifiable {
    let trustedNodeId: String
    var trustedDeviceName: String
    let publicKeyFingerprint: String
    let publicKeyBase64: String
    let trustCreatedAt: Date
    var lastSeenAt: Date
    let systemId: String
    let protocolVersion: Int
    var lastHost: String?
    var lastPairingPort: Int?

    var id: String { trustedNodeId }
}
