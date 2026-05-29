import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore
import NoxShrineCore

/// Resolves constellation role labels to SF Symbols that exist on this Mac.
enum NoxConstellationRoleIconResolver {
    static func symbol(for role: NoxConstellationAssignedRole) -> String {
        validated(primary: NoxConstellationRoleIcons.symbol(for: role), role: role)
    }

    static func symbolForRoleLabel(_ label: String) -> String? {
        guard let primary = NoxConstellationRoleIcons.symbolForRoleLabel(label) else { return nil }
        if label.lowercased().contains("beacon") {
            return NoxSFSymbol.validated(
                primary,
                fallback: NoxConstellationRoleIcons.beaconAlternative,
                ultimate: "dot.radiowaves.left.and.right"
            )
        }
        if label.lowercased().contains("nox i") {
            return NoxSFSymbol.validated(
                primary,
                fallback: NoxConstellationRoleIcons.noxIAlternative,
                ultimate: "sparkles"
            )
        }
        if label.lowercased().contains("station") {
            return NoxSFSymbol.validated(primary, fallback: NoxConstellationRoleIcons.stationAlternative)
        }
        if label.lowercased().contains("satellite") {
            return NoxSFSymbol.validated(primary, fallback: NoxConstellationRoleIcons.satelliteAlternative)
        }
        return NoxSFSymbol.validated(primary)
    }

    private static func validated(primary: String, role: NoxConstellationAssignedRole) -> String {
        switch role {
        case .noxI:
            return NoxSFSymbol.validated(
                primary,
                fallback: NoxConstellationRoleIcons.noxIAlternative,
                ultimate: "sparkles"
            )
        case .beacon:
            return NoxSFSymbol.validated(
                primary,
                fallback: NoxConstellationRoleIcons.beaconAlternative,
                ultimate: "dot.radiowaves.left.and.right"
            )
        case .station:
            return NoxSFSymbol.validated(primary, fallback: NoxConstellationRoleIcons.stationAlternative)
        case .satellite:
            return NoxSFSymbol.validated(primary, fallback: NoxConstellationRoleIcons.satelliteAlternative)
        }
    }
}
