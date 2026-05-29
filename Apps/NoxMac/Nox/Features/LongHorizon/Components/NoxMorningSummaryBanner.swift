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

struct NoxMorningSummaryBanner: View {
  let summary: NoxMorningSummary

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.sm) {
      Text(summary.headline)
        .font(NoxTypography.reflection)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.92))
        .fixedSize(horizontal: false, vertical: true)

      ForEach(summary.supportingLines, id: \.self) { line in
        Text(line)
          .font(NoxTypography.reflectionSoft)
          .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.62))
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .noxSurface(.major)
  }
}
