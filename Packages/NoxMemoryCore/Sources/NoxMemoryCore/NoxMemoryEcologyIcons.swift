import Foundation

/// SF Symbol names for memory ecology layers (validated in the app shell).
public enum NoxMemoryEcologyIcons {
    public static let galaxyPrimary = "sparkles"
    public static let galaxyAlternative = "circle.grid.2x2.fill"

    public static let orbitPrimary = "point.3.connected.trianglepath.dotted"
    public static let orbitAlternative = "clock.arrow.circlepath"

    public static let deepSpacePrimary = "archivebox.fill"
    public static let deepSpaceAlternative = "internaldrive"

    public static func symbol(for layer: NoxMemoryEcologyPrimaryLayer) -> String {
        switch layer {
        case .galaxy: galaxyPrimary
        case .orbit: orbitPrimary
        case .deepSpace: deepSpacePrimary
        }
    }
}
