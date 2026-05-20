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

struct NoxContextExplanationCard: View {
  let reason: NoxInferenceReason

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.xs) {
      Text("Why this appears")
        .noxSectionLabel()

      Text(reason.headline)
        .font(NoxTypography.continuityDetail)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.88))
        .fixedSize(horizontal: false, vertical: true)

      if let detail = reason.detail {
        Text(detail)
          .noxMetadata()
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(.leading, NoxSpacing.sm)
    .overlay(alignment: .leading) {
      Rectangle()
        .fill(NoxDesignTokens.ColorRole.accent.opacity(0.28))
        .frame(width: 1)
    }
  }
}
