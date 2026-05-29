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

struct NoxLocalFirstBadge: View {
    var body: some View {
        HStack(spacing: NoxSpacing.xs) {
            NoxIcon(systemName: "lock.shield", role: .inline)
            Text(NoxTrustContent.localBadge)
                .font(NoxTypography.metadata)
        }
        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.82))
    }
}
