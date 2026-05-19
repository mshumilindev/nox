import SwiftUI

struct NoxEraSurface: View {
  let candidates: [NoxTypedMemoryEntity]
  var eraHints: [NoxEraEvolutionHint] = []

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.sm) {
      if let observation = eraObservationLine {
        Text(observation)
          .font(NoxTypography.caption)
          .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.52))
          .fixedSize(horizontal: false, vertical: true)
      }

      ForEach(candidates) { entity in
        VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
          Text(entity.title)
            .font(NoxTypography.actionEmphasis)
            .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.88))
          Text(entity.summary)
            .font(NoxTypography.caption)
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.5))
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(NoxSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
      }
    }
  }

  private var eraObservationLine: String? {
    guard let hint = eraHints.first, hint.resonance >= 0.38 else { return nil }
    return NoxTemporalContinuityCopyBuilder.eraObservation(for: hint)
  }

  private var cardBackground: some View {
    RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
      .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(NoxDesignTokens.Opacity.subtle))
  }
}
