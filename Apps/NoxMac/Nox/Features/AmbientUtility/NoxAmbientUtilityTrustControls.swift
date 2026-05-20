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

struct NoxAmbientUtilityTrustControls: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.lg) {
            Text("Notifications")
                .noxSectionLabel()

            Text("Occasional local notes — not reminders or coaching.")
                .noxMetadata()
                .fixedSize(horizontal: false, vertical: true)

            NoxSettingsToggleRow(
                title: "Allow notifications",
                detail: "macOS notifications only, with cooldowns.",
                isOn: Binding(
                    get: { environment.preferences.ambientUtility.ambientNotificationsEnabled },
                    set: { environment.setAmbientNotificationsEnabled($0) }
                )
            )
        }
        .noxSurface(.soft, padding: NoxSpacing.lg)
    }
}
