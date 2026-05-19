import SwiftUI

struct NoxSemanticArcCard: View {
  let arc: NoxSemanticArc

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.xs) {
      Text(arc.label)
        .font(NoxTypography.continuityDetail)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))

      Text(arc.continuityState.rawValue.capitalized)
        .font(NoxTypography.caption)
        .foregroundStyle(NoxDesignTokens.ColorRole.continuityTint.opacity(0.7))

      if let detail = arc.detailLine {
        Text(detail)
          .noxMetadata()
      }

      Text(evolutionLine)
        .font(NoxTypography.caption)
        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.48))
    }
    .noxSurface(.standard)
  }

  private var evolutionLine: String {
    "\(arc.spanCount) spans · \(arc.evolution.rawValue)"
  }
}
