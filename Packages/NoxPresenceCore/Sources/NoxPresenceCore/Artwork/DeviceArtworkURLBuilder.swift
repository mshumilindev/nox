import Foundation

nonisolated public enum DeviceArtworkFormat: String, Sendable {
    case png
}

nonisolated public enum DeviceArtworkURLBuilder {
    static let baseURL = URL(string: "https://raw.githubusercontent.com/littlebyteorg/apple-device-images/main/")!
    static let preferredFormats: [DeviceArtworkFormat] = [.png]

    public static func imageURLs(deviceKey: String, colorKey: String, darkMode: Bool = true) -> [URL] {
        let colorNames = darkMode ? ["\(colorKey)_dark", colorKey] : [colorKey]
        var candidates: [String] = []
        for color in colorNames {
            candidates.append("device/\(deviceKey)/\(color).png")
        }
        candidates.append("device/\(deviceKey).png")
        candidates.append("device-lowres/\(deviceKey).png")

        var seen = Set<String>()
        return candidates.compactMap { path in
            guard seen.insert(path).inserted else { return nil }
            return URL(string: path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path, relativeTo: baseURL)
        }
    }
}
