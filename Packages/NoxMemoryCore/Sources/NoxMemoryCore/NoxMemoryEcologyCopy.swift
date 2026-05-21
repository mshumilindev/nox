import Foundation

/// Memory ecology layer language — section and empty-state copy.
public enum NoxMemoryEcologyCopy {
    public static let orbitEmpty = "No nearby Orbit memory right now."
    public static let deepSpaceEmpty = "No archival continuity in this range yet."
    public static let beaconGateTitle = "No memory browser on this device"
    public static let beaconGateDetail =
        "Beacons stay ambient. Open Nox on Nox I, a Station, or a Satellite to browse memory."

    public static func deepSpacePeriodHint(period: NoxMemoryPeriod) -> String {
        switch period {
        case .today:
            return "Older continuity and dormant eras"
        case .yesterday:
            return "Yesterday"
        case .lastSevenDays:
            return "Last seven days"
        }
    }
}
