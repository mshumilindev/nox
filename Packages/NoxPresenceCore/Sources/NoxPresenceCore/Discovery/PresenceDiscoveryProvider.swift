import Foundation
import NoxCore

public protocol PresenceDiscoveryProvider: AnyObject {
    var onNodesChanged: (@Sendable ([NoxDiscoveredNode]) -> Void)? { get set }
    func start(identity: NoxNodeIdentity, port: UInt16, presenceToken: String) throws
    func stop()
}
