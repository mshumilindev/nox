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

/// Trust boundaries — one composed surface, not stacked slabs.
struct NoxTrustBoundariesList: View {
  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.lg) {
      ForEach(Array(NoxTrustContent.sections.enumerated()), id: \.element.id) { index, section in
        boundarySection(section)
        if index < NoxTrustContent.sections.count - 1 {
          Divider().opacity(0.2)
        }
      }
    }
    .noxSurface(.soft, padding: NoxSpacing.lg)
  }

  private func boundarySection(_ section: NoxTrustSection) -> some View {
    VStack(alignment: .leading, spacing: NoxSpacing.xs) {
      Text(section.title)
        .font(NoxTypography.continuityDetail)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))

      ForEach(section.lines, id: \.self) { line in
        Text(line)
          .noxMetadata()
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}
