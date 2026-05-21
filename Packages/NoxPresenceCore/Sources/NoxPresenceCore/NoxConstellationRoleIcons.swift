import Foundation

/// SF Symbol names for constellation device roles (validated in the app shell).
public enum NoxConstellationRoleIcons {
    public static let noxIPrimary = "circle.hexagongrid.fill"
    public static let noxIAlternative = "sparkles.rectangle.stack"

    public static let stationPrimary = "internaldrive"
    public static let stationAlternative = "archivebox"

    public static let satellitePrimary = "point.3.connected.trianglepath.dotted"
    public static let satelliteAlternative = "sensor"

    public static let beaconPrimary = "sensor.tag.radiowaves.forward"
    public static let beaconAlternative = "wave.3.right.circle"

    public static func symbol(for role: NoxConstellationAssignedRole) -> String {
        switch role {
        case .noxI: noxIPrimary
        case .station: stationPrimary
        case .satellite: satellitePrimary
        case .beacon: beaconPrimary
        }
    }

    /// Maps constellation candidate / trusted role labels to role icons.
    public static func symbolForRoleLabel(_ label: String) -> String? {
        let normalized = label.lowercased()
        if normalized.contains("beacon") {
            return beaconPrimary
        }
        if normalized.contains("station") {
            return stationPrimary
        }
        if normalized.contains("satellite") {
            return satellitePrimary
        }
        if normalized.contains("nox i") {
            return noxIPrimary
        }
        return nil
    }
}
