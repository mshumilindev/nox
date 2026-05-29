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

struct NoxSensitiveContextExplanation: View {
  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.md) {
      Text("Sensitive context visibility")
        .font(NoxTypography.continuityDetail)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))

      VStack(alignment: .leading, spacing: NoxSpacing.sm) {
        ForEach(NoxSemanticVisibilityMode.allCases, id: \.self) { mode in
          HStack(alignment: .firstTextBaseline, spacing: NoxSpacing.md) {
            Text(mode.title)
              .font(NoxTypography.caption)
              .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.78))
              .frame(width: 108, alignment: .leading)
            Text(mode.detail)
              .noxMetadata()
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
    }
    .noxSurface(.soft, padding: NoxSpacing.lg)
  }
}
