import Foundation

nonisolated enum NoxPresenceModelConfidence: String, Sendable {
    case exact
    case family
    case generic
}

nonisolated struct NoxPresenceHardwareIdentity: Hashable, Sendable {
    let confidence: NoxPresenceModelConfidence
    let deviceKey: String?
    let colorKey: String?
    let fallbackKind: NoxPresenceDeviceKind
    let showsConcreteAppleDevice: Bool

    static func generic(fallbackKind: NoxPresenceDeviceKind = .mac) -> NoxPresenceHardwareIdentity {
        NoxPresenceHardwareIdentity(
            confidence: .generic,
            deviceKey: nil,
            colorKey: nil,
            fallbackKind: fallbackKind,
            showsConcreteAppleDevice: false
        )
    }

    var cacheKey: String {
        switch confidence {
        case .exact: "exact|\(deviceKey ?? "")|\(colorKey ?? "")"
        case .family: "family|\(fallbackKind.rawValue)"
        case .generic: "generic|\(fallbackKind.rawValue)"
        }
    }
}
