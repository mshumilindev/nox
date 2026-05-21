import Foundation

/// Peripheral memory awaiting absorption into Galaxy (Satellite / Beacon).
public struct NoxMemoryOrbitItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let deviceName: String
    public let roleLine: String
    public let detail: String
    public let isBeaconClass: Bool

    public init(
        id: String,
        deviceName: String,
        roleLine: String,
        detail: String,
        isBeaconClass: Bool
    ) {
        self.id = id
        self.deviceName = deviceName
        self.roleLine = roleLine
        self.detail = detail
        self.isBeaconClass = isBeaconClass
    }
}

/// Archival / long-horizon memory row in Deep Space.
public struct NoxMemoryDeepSpaceEntry: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let detail: String?

    public init(id: String, title: String, detail: String? = nil) {
        self.id = id
        self.title = title
        self.detail = detail
    }
}
