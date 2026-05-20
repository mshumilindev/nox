import Foundation
import NoxCore

public protocol PresenceTransportProvider: AnyObject {
    var onMessageReceived: (@Sendable (NoxMeshMessage, String?) -> Void)? { get set }
    func startListening(port: UInt16) throws
    func stopListening()
    func send(_ message: NoxMeshMessage, to host: String, port: Int) async throws
}
