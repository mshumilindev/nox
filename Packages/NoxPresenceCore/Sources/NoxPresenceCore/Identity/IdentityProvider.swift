import Foundation
import NoxCore

/// Node identity source — local today; CloudKit-ready later.
public protocol IdentityProvider: Sendable {
    func loadOrCreateIdentity() throws -> NoxNodeIdentity
    func currentIdentity() -> NoxNodeIdentity?
    func resetIdentity() throws -> NoxNodeIdentity
    func signingPrivateKey() throws -> Data
}
