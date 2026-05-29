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

/// Beacons do not expose the full memory ecology browser.
struct NoxMemoryBeaconEcologyGate: View {
    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            Text(NoxMemoryEcologyCopy.beaconGateTitle)
                .font(NoxTypography.body)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.88))
            Text(NoxMemoryEcologyCopy.beaconGateDetail)
                .font(NoxTypography.caption)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .noxSurface(.inset, padding: NoxSpacing.lg)
    }
}
