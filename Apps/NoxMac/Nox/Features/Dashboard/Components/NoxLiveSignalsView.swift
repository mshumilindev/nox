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

struct NoxLiveSignalsView: View {
  @Environment(AppEnvironment.self) private var environment
  let signals: [NoxLiveSignal]
  var compact: Bool = false

  private var presentation: NoxLiveContextPresentation {
    NoxLiveContextPresenter.present(
      signals: signals,
      semanticContext: environment.semanticInference,
      contextLabel: environment.activeContextLabel,
      compact: compact
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.md) {
      Text(compact ? "Live" : "Live context")
        .noxSectionLabel()

      if presentation.isEmpty {
        placeholderRow
      } else {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
          if !presentation.pulse.isEmpty {
            pulseSection
          }
          if !presentation.detail.isEmpty {
            detailSection
          }
        }
        .noxSurface(.soft)
      }
    }
  }

  private var pulseSection: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.sm) {
      ForEach(presentation.pulse) { item in
        HStack(alignment: .firstTextBaseline, spacing: NoxSpacing.sm) {
          Text(item.timestamp, style: .time)
            .font(NoxTypography.timelineStamp)
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.42))
            .frame(width: 44, alignment: .leading)

          Text(item.text)
            .font(NoxTypography.body)
            .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }

  private var detailSection: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.xs) {
      ForEach(presentation.detail) { item in
        HStack(alignment: .firstTextBaseline, spacing: NoxSpacing.sm) {
          Text("·")
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.35))
            .frame(width: 44, alignment: .center)
          Text(item.text)
            .font(NoxTypography.caption)
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.55))
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
    .padding(.leading, 0)
  }

  private var placeholderRow: some View {
    HStack(spacing: NoxSpacing.sm) {
      Circle()
        .fill(NoxDesignTokens.ColorRole.presenceMuted)
        .frame(width: 4, height: 4)
      Text("Quiet for now")
        .font(NoxTypography.caption)
        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.5))
    }
    .padding(.vertical, NoxSpacing.sm)
  }
}
