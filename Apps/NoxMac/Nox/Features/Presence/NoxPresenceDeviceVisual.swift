import SwiftUI
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

/// Presence hardware visual — AppleDB artwork with Nox generic fallback.
struct NoxPresenceDeviceVisual: View {
    let identity: NoxPresenceHardwareIdentity
    let tone: NoxPresenceCardTone
    var large: Bool = false
    var isGroupedDevice = false

    var body: some View {
        NoxDeviceArtworkView(
            identity: identity,
            tone: tone,
            large: large,
            isGroupedDevice: isGroupedDevice
        )
    }
}
