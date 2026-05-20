import Foundation

/// Bonjour / BLE source — governs whether hardware fields may resolve concrete device artwork.
nonisolated enum NoxAppleDiscoverySource: String, Sendable, Codable {
    case deviceInfo
    case mobileSync
    case companionLink
    case homeKit
    case airplay
    case raop
    case bluetoothContinuity
    case noxMesh

    init?(bonjourServiceType: String) {
        switch bonjourServiceType {
        case "_device-info._tcp.": self = .deviceInfo
        case "_apple-mobdev2._tcp.": self = .mobileSync
        case "_companion-link._tcp.": self = .companionLink
        case "_homekit._tcp.": self = .homeKit
        case "_airplay._tcp.": self = .airplay
        case "_raop._tcp.": self = .raop
        default: return nil
        }
    }

    var trustsHardwareFields: Bool {
        switch self {
        case .deviceInfo, .mobileSync, .companionLink, .bluetoothContinuity, .noxMesh:
            true
        case .homeKit, .airplay, .raop:
            false
        }
    }

    var trustRank: Int {
        switch self {
        case .deviceInfo: 50
        case .mobileSync: 45
        case .companionLink: 40
        case .noxMesh: 35
        case .bluetoothContinuity: 30
        case .homeKit: 10
        case .airplay, .raop: 0
        }
    }

    func merged(with other: NoxAppleDiscoverySource?) -> NoxAppleDiscoverySource {
        guard let other else { return self }
        return trustRank >= other.trustRank ? self : other
    }
}
