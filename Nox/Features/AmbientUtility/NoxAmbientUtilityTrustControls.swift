import SwiftUI

struct NoxAmbientUtilityTrustControls: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.lg) {
            Text("Ambient notifications")
                .noxSectionLabel()

            Text("Rare continuity surfaces — not reminders, tasks, or coaching.")
                .noxMetadata()
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: NoxSpacing.md) {
                VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
                    Text("Allow ambient notifications")
                        .font(NoxTypography.continuityDetail)
                    Text("Local macOS notifications only. Cooldowns and silence rules apply.")
                        .noxMetadata()
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .allowsHitTesting(false)

                Toggle(
                    "",
                    isOn: Binding(
                        get: { environment.preferences.ambientUtility.ambientNotificationsEnabled },
                        set: { environment.setAmbientNotificationsEnabled($0) }
                    )
                )
                .labelsHidden()
            }
        }
        .noxSurface(.soft, padding: NoxSpacing.lg)
    }
}
