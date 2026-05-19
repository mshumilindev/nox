import SwiftUI

struct NoxSemanticArcCard: View {
  let arc: NoxSemanticArc

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.xs) {
      Text(arc.label)
        .font(NoxTypography.continuityDetail)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
        .lineLimit(1)

      Text(arc.continuityState.rawValue.capitalized)
        .font(NoxTypography.caption)
        .foregroundStyle(NoxDesignTokens.ColorRole.continuityTint.opacity(0.7))
        .lineLimit(1)

      NoxFixedLineText(
        text: arc.detailLine,
        lineHeight: NoxSurfaceLayout.timelineMetadataLineHeight,
        font: NoxTypography.caption,
        color: NoxDesignTokens.ColorRole.textSecondary.opacity(0.52)
      )

      Text(evolutionLine)
        .font(NoxTypography.caption)
        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.48))
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, minHeight: NoxSurfaceLayout.arcCardMinHeight, alignment: .topLeading)
    .noxSurface(.standard)
  }

  private var evolutionLine: String {
    "\(arc.spanCount) spans · \(arc.evolution.rawValue)"
  }
}
