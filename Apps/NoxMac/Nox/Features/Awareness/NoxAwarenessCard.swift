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

struct NoxAwarenessCard: View {
  let snapshot: NoxAwarenessSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.sm) {
      Text("Awareness")
        .noxSectionLabel()

      Text(snapshot.level.title)
        .font(NoxTypography.continuity)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))

      Text(snapshot.scopeLabel)
        .font(NoxTypography.continuityDetail)
        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.65))
        .fixedSize(horizontal: false, vertical: true)

      if let confidence = snapshot.confidenceLine {
        Text(confidence)
          .noxMetadata()
      }

      if let visibility = snapshot.visibilityLine {
        Text(visibility)
          .font(NoxTypography.caption)
          .foregroundStyle(NoxDesignTokens.ColorRole.accent.opacity(0.65))
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .noxSurface(.soft)
  }
}
