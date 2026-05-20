import Foundation

/// Apple-ecosystem device identity inferred from friendly host names — product-facing only.
nonisolated enum NoxPresenceDeviceKind: String, Sendable {
    case macBookPro
    case macBookAir
    case iMac
    case macStudio
    case macMini
    case iPhone
    case iPad
    case appleWatch
    case appleTV
    case homePod
    case mac

    var typeLabel: String {
        switch self {
        case .macBookPro: "MacBook Pro"
        case .macBookAir: "MacBook Air"
        case .iMac: "iMac"
        case .macStudio: "Mac Studio"
        case .macMini: "Mac mini"
        case .iPhone: "iPhone"
        case .iPad: "iPad"
        case .appleWatch: "Apple Watch"
        case .appleTV: "Apple TV"
        case .homePod: "HomePod"
        case .mac: "Mac"
        }
    }

    static func confidentlyInfer(from deviceName: String) -> NoxPresenceDeviceKind? {
        let normalized = deviceName.lowercased()
        if normalized.contains("macbook pro") { return .macBookPro }
        if normalized.contains("macbookpro") { return .macBookPro }
        if normalized.contains("macbook air") { return .macBookAir }
        if normalized.contains("macbookair") { return .macBookAir }
        if normalized.contains("macbook") { return .macBookPro }
        if normalized.contains("mac studio") { return .macStudio }
        if normalized.contains("macstudio") { return .macStudio }
        if normalized.contains("mac mini") { return .macMini }
        if normalized.contains("macmini") { return .macMini }
        if normalized.contains("imac") { return .iMac }
        if normalized.contains("iphone") { return .iPhone }
        if normalized.range(of: #"iphone\d"#, options: .regularExpression) != nil { return .iPhone }
        if normalized.contains("ipad") { return .iPad }
        if normalized.range(of: #"ipad\d"#, options: .regularExpression) != nil { return .iPad }
        if normalized.contains("watch") { return .appleWatch }
        if normalized.contains("homepod") || normalized.contains("audioaccessory") { return .homePod }
        if normalized.contains("apple tv") || normalized.contains("appletv") { return .appleTV }
        if normalized.contains("j105") || normalized.contains("j42") { return .appleTV }
        if normalized.contains("'s mac") || normalized.hasSuffix(" mac") {
            return .macBookPro
        }
        return nil
    }
}

enum NoxPresenceCardTone: Sendable {
    case nearby
    case unavailable
    case awaitingTrust
    case trusted
    case expanding

    var contextLine: String {
        switch self {
        case .nearby:
            "Nearby Nox presence detected"
        case .unavailable:
            "Nearby Apple device detected"
        case .awaitingTrust:
            "Ready to join your environment"
        case .trusted:
            "Part of your active Nox environment"
        case .expanding:
            "Expanding your environment…"
        }
    }
}

enum NoxPresenceDeviceCopy {
    static func subtitle(for kind: NoxPresenceDeviceKind, tone: NoxPresenceCardTone) -> String {
        switch tone {
        case .nearby:
            switch kind {
            case .iMac, .macStudio, .macMini:
                return "Available to extend your Nox environment"
            case .iPhone, .iPad:
                return "Nearby Apple device with Nox presence"
            default:
                return "Nearby Nox presence detected"
            }
        case .unavailable:
            switch kind {
            case .iMac, .macBookPro, .macBookAir, .macStudio, .macMini, .mac:
                return "Nox is not paired here yet"
            case .iPhone, .iPad:
                return "Available for a Nox setup invite"
            case .appleTV, .homePod, .appleWatch:
                return "Nearby Apple ecosystem presence"
            }
        case .awaitingTrust:
            return "Waiting for your approval"
        case .trusted:
            return "Part of your environment"
        case .expanding:
            return "Connecting quietly…"
        }
    }
}
