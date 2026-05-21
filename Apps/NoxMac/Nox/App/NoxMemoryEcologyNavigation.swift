import Foundation
import NoxCore
import NoxMemoryCore
import NoxPresenceCore

extension AppEnvironment {

    /// Current device role for memory ecology (NoxMac is the canonical Nox I host).
    var memoryEcologyDeviceRole: NoxMemoryEcologyDeviceRole {
        if NoxConstellationRoleResolver.isNoxIActiveOnThisDevice(isMacOSCanonicalApp: true) {
            return .noxI
        }
        return .noxI
    }

    var memoryEcologyOwnership: NoxMemoryEcologyOwnership {
        NoxMemoryEcologyOwnershipResolver.resolve(
            currentDeviceRole: memoryEcologyDeviceRole,
            hasConfiguredStation: presenceMesh.hasConfiguredNoxStation
        )
    }

    func navigationTitle(for destination: NoxSemanticDestination) -> String {
        if destination == .memory {
            return memoryEcologyOwnership.navigationTitle
        }
        return destination.title
    }

    func chromeSubtitle(for destination: NoxSemanticDestination) -> String {
        if destination == .memory {
            return memoryEcologyOwnership.chromeSubtitle
        }
        switch destination {
        case .now: return "Live activity context"
        case .presence: return "Nearby devices"
        case .threads: return "Recurring activity patterns"
        case .patterns: return "Behavior patterns"
        case .observatory: return "Combined activity signals"
        case .reflections: return "Recent pattern summaries"
        case .local: return "On-device only"
        case .trust: return "Boundaries and control"
        case .memory: return memoryEcologyOwnership.chromeSubtitle
        }
    }
}
