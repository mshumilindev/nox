import Foundation

public nonisolated enum NoxMeshError: Error, LocalizedError, Equatable, Sendable {
    case keychainFailed(OSStatus)
    case identityUnavailable
    case transportUnavailable
    case verificationFailed(String)
    case staleMessage
    case replayedNonce
    case inviteExpired
    case inviteAlreadyUsed

    public var errorDescription: String? {
        switch self {
        case .keychainFailed(let s): "Keychain error \(s)"
        case .identityUnavailable: "Node identity unavailable"
        case .transportUnavailable: "Local transport unavailable"
        case .verificationFailed(let r): r
        case .staleMessage: "Message timestamp outside allowed window"
        case .replayedNonce: "Nonce already used"
        case .inviteExpired: "Pairing invite expired"
        case .inviteAlreadyUsed: "Pairing invite already used"
        }
    }
}
