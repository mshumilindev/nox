import Foundation

nonisolated struct AppleDBDeviceRecord: Codable, Sendable, Equatable {
    let key: String
    let imageKey: String?
    let colors: [AppleDBDeviceColor]?

    var resolvedImageKey: String { imageKey ?? key }

    var preferredColorKey: String? {
        colors?.first?.key ?? colors?.first?.name
    }
}

nonisolated struct AppleDBDeviceColor: Codable, Sendable, Equatable {
    let name: String
    let key: String?
}
