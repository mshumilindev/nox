import SwiftUI

struct NoxSemanticArcCard: View {
  let arc: NoxSemanticArc
  var evolution: NoxMemoryEvolutionSnapshot = .neutral

  private var presentation: NoxTimelineRowPresentation {
    let profile = evolution.agingProfiles.first { $0.subjectId == arc.id }
    let input = NoxMemoryAgingPresenter.Input(
      subjectId: arc.id,
      lastActiveAt: arc.lastSeenAt,
      recurrenceStrength: arc.evolution == .strengthening ? 0.5 : 0.3,
      continuityGravity: arc.strength,
      temporalWeight: evolution.temporalWeights[arc.id],
      confidence: arc.strength,
      isResumed: arc.continuityState == .resurfaced,
      at: Date()
    )
    return NoxMemoryAgingPresenter.presentation(profile: profile, input: input)
  }

  private var temporalState: NoxMemoryTemporalState {
    presentation.temporalState
  }

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.xs) {
      Text(arc.label)
        .font(NoxTypography.continuityDetail)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(presentation.titleOpacity))
        .lineLimit(1)

      Text(stateCaption)
        .font(NoxTypography.caption)
        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(presentation.metadataOpacity))
        .lineLimit(1)

      NoxFixedLineText(
        text: arcDetail,
        lineHeight: NoxSurfaceLayout.timelineMetadataLineHeight,
        font: NoxTypography.caption,
        color: NoxDesignTokens.ColorRole.textSecondary.opacity(presentation.detailOpacity)
      )

      Text(NoxTemporalContinuityCopyBuilder.arcEvolutionLine(arc: arc, state: temporalState))
        .font(NoxTypography.caption)
        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(presentation.detailOpacity * 0.95))
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, minHeight: NoxSurfaceLayout.arcCardMinHeight, alignment: .topLeading)
    .noxSurface(.standard)
  }

  private var stateCaption: String {
    switch temporalState {
    case .resurfacing: return "returned recently"
    case .fading: return "fading"
    case .dormant: return "quiet"
    case .archival: return "distant"
    case .active: return continuityStateLabel(arc.continuityState)
    }
  }

  private var arcDetail: String? {
    NoxTemporalContinuityCopyBuilder.arcDetail(arc: arc, state: temporalState, thread: nil)
  }

  private func continuityStateLabel(_ state: NoxArcContinuityState) -> String {
    switch state {
    case .active: return "Active"
    case .merging: return "Increasing overlap"
    case .fading: return "Fading"
    case .dormant: return "Quiet"
    case .resurfaced: return "Returned"
    }
  }
}
