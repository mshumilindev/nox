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

/// Resolved device artwork inputs shared by Constellation cards and the Expand modal.
struct NoxConstellationDeviceArtworkPresentation: Sendable, Equatable {
    let hardwareIdentity: NoxPresenceHardwareIdentity
    let isGroupedDevice: Bool
    let tone: NoxPresenceCardTone

    /// Same resolver path as nearby Constellation cards — do not re-resolve in the modal.
    static func nearby(
        node: NoxDiscoveredNode,
        kind: NoxPresenceDeviceKind,
        tone: NoxPresenceCardTone
    ) -> NoxConstellationDeviceArtworkPresentation {
        NoxConstellationDeviceArtworkPresentation(
            hardwareIdentity: NoxPresenceHardwareIdentityResolver.hardwareIdentity(
                for: node,
                expectedKind: kind
            ),
            isGroupedDevice: node.appleGroupMemberNames.count > 1,
            tone: tone
        )
    }
}
