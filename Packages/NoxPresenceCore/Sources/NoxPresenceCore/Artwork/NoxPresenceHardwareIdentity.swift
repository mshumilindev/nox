import Foundation
import NoxCore

public nonisolated enum NoxPresenceModelConfidence: String, Sendable {
    case exact
    case family
    case generic
}

public nonisolated struct NoxPresenceHardwareIdentity: Hashable, Sendable {
    public let confidence: NoxPresenceModelConfidence
    public let deviceKey: String?
    public let colorKey: String?
    public let fallbackKind: NoxPresenceDeviceKind
    public let showsConcreteAppleDevice: Bool

    public init(
        confidence: NoxPresenceModelConfidence,
        deviceKey: String?,
        colorKey: String?,
        fallbackKind: NoxPresenceDeviceKind,
        showsConcreteAppleDevice: Bool
    ) {
        self.confidence = confidence
        self.deviceKey = deviceKey
        self.colorKey = colorKey
        self.fallbackKind = fallbackKind
        self.showsConcreteAppleDevice = showsConcreteAppleDevice
    }

    public static func generic(fallbackKind: NoxPresenceDeviceKind = .mac) -> NoxPresenceHardwareIdentity {
        NoxPresenceHardwareIdentity(
            confidence: .generic,
            deviceKey: nil,
            colorKey: nil,
            fallbackKind: fallbackKind,
            showsConcreteAppleDevice: false
        )
    }

    public var cacheKey: String {
        switch confidence {
        case .exact: "exact|\(deviceKey ?? "")|\(colorKey ?? "")"
        case .family: "family|\(fallbackKind.rawValue)"
        case .generic: "generic|\(fallbackKind.rawValue)"
        }
    }
}
