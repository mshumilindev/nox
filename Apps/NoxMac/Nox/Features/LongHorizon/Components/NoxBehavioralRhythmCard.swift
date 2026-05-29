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

struct NoxBehavioralRhythmCard: View {
  let entity: NoxTypedMemoryEntity

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
      Text(entity.title)
        .font(NoxTypography.continuityDetail)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.88))

      Text(entity.summary)
        .noxMetadata()
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, NoxSpacing.xs)
  }
}
