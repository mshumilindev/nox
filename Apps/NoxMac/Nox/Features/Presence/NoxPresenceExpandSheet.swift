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

struct NoxPresenceExpandSheet: View {
    let deviceName: String
    let deviceKind: NoxPresenceDeviceKind
    let hardwareIdentity: NoxPresenceHardwareIdentity
    let onBeginExpansion: () -> Void
    let onInviteNearbyMac: () -> Void
    let onCopySetupLink: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.lg) {
            HStack(spacing: NoxSpacing.lg) {
                NoxPresenceDeviceVisual(identity: hardwareIdentity, tone: .nearby, large: true)
                VStack(alignment: .leading, spacing: NoxSpacing.xs) {
                    Text(NoxConstellationCopy.expandSheetTitle)
                        .font(.system(size: 18, weight: .semibold))
                    Text(deviceName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                }
            }

            Text(NoxConstellationCopy.expandSheetDetail)
                .font(.system(size: 13))
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: NoxSpacing.sm) {
                Button(NoxConstellationCopy.beginExpansion) {
                    onBeginExpansion()
                    dismiss()
                }
                .buttonStyle(NoxPresencePrimaryButtonStyle())
                .frame(maxWidth: .infinity)

                Button(NoxConstellationCopy.inviteDevice) {
                    onInviteNearbyMac()
                }
                .frame(maxWidth: .infinity)

                Button(NoxConstellationCopy.copySetupLink) {
                    onCopySetupLink()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, NoxSpacing.sm)

            Spacer(minLength: 0)
        }
        .padding(NoxSpacing.xl)
        .frame(width: 400)
        .frame(minHeight: 320)
        .background(NoxDesignTokens.ColorRole.canvas)
    }
}
