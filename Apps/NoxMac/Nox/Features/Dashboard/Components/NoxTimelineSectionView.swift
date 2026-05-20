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

struct NoxTimelineSectionView: View {
  let section: NoxTimelineSection

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.sm) {
      Text(section.layer.title)
        .font(NoxTypography.sectionLabel)
        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.62))
        .textCase(.uppercase)

      VStack(alignment: .leading, spacing: 0) {
        ForEach(Array(section.items.enumerated()), id: \.element.id) { index, block in
          NoxTimelineRowView(
            block: block,
            isFirst: index == 0,
            isLast: index == section.items.count - 1
          )
        }
      }
    }
  }
}
