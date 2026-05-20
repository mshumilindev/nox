import Foundation

/// Node identity source — local today; CloudKit-ready later.
protocol IdentityProvider: Sendable {
    func loadOrCreateIdentity() throws -> NoxNodeIdentity
    func currentIdentity() -> NoxNodeIdentity?
    func resetIdentity() throws -> NoxNodeIdentity
    func signingPrivateKey() throws -> Data
}
