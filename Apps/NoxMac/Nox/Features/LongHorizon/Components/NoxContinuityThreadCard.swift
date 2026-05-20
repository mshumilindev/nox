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

struct NoxContinuityThreadCard: View {
  let thread: NoxContinuityThread
  var evolution: NoxMemoryEvolutionSnapshot = .neutral

  private var presentation: NoxTimelineRowPresentation {
    NoxTemporalMemoryRowPresenter.presentation(for: thread, evolution: evolution)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.xs) {
      HStack(alignment: .firstTextBaseline, spacing: NoxSpacing.sm) {
        Text(NoxContinuityResurfacingPresenter.threadDisplayTitle(thread))
          .font(NoxTypography.continuity)
          .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(presentation.titleOpacity))
          .lineLimit(2)

        if let stamp = NoxTemporalMemoryRowPresenter.continuityCardStamp(
          thread: thread,
          evolution: evolution
        ) {
          Text(stamp)
            .font(NoxTypography.caption)
            .foregroundStyle(
              NoxDesignTokens.ColorRole.textSecondary.opacity(presentation.metadataOpacity)
            )
            .lineLimit(1)
        }
      }

      Text(NoxTemporalMemoryRowPresenter.continuityCardDetail(thread: thread, evolution: evolution))
        .font(NoxTypography.caption)
        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(presentation.detailOpacity))
        .lineLimit(2)

      if let relation = presentation.relationLine {
        Text(relation)
          .font(NoxTypography.caption)
          .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(presentation.detailOpacity * 0.92))
          .lineLimit(1)
      }
    }
    .noxSurface(.standard)
  }
}
