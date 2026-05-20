import Foundation

nonisolated public enum NoxPresenceFamilyArtwork {
    public static func imageKey(for kind: NoxPresenceDeviceKind) -> String? {
        switch kind {
        case .iPhone: "iPhone14,2"
        case .iPad: "iPad13,18"
        case .macBookPro: "Mac14,7"
        case .macBookAir: "Mac14,2"
        case .iMac: "iMac21,1"
        case .macStudio: "Mac13,2"
        case .macMini: "Mac14,3"
        case .mac: "Mac14,7"
        case .appleWatch: "Watch7,2"
        case .appleTV: "AppleTV14,1"
        case .homePod: "AudioAccessory1,1"
        }
    }

    public static func defaultColor(for deviceKey: String) -> String {
        if deviceKey.hasPrefix("Watch") { return "Midnight" }
        if deviceKey.hasPrefix("AudioAccessory") { return "Space Gray" }
        if deviceKey.hasPrefix("iMac") { return "Silver" }
        if deviceKey.hasPrefix("iPhone") || deviceKey.hasPrefix("iPad") { return "Graphite" }
        return "Space Gray"
    }
}
