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

struct NoxContextualNudgeBanner: View {
    let nudge: NoxContextualNudge

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xs) {
            Text(nudge.line)
                .font(NoxTypography.continuityDetail)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
            if let detail = nudge.detail {
                Text(detail)
                    .noxMetadata()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .noxSurface(.soft, padding: NoxSpacing.md)
    }
}
