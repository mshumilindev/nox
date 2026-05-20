import Foundation

public nonisolated struct AppleDBDeviceRecord: Codable, Sendable, Equatable {
    public let key: String
    public let imageKey: String?
    public let colors: [AppleDBDeviceColor]?

    public var resolvedImageKey: String { imageKey ?? key }

    public var preferredColorKey: String? {
        colors?.first?.key ?? colors?.first?.name
    }
}

public nonisolated struct AppleDBDeviceColor: Codable, Sendable, Equatable {
    public let name: String
    public let key: String?
}
