import SwiftUI

/// Very light era surfacing — observational, not a hero card.
struct NoxMemoryEraObservationView: View {
  let line: String

  var body: some View {
    Text(line)
      .font(NoxTypography.caption)
      .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.52))
      .fixedSize(horizontal: false, vertical: true)
      .padding(.bottom, NoxSpacing.xs)
  }
}
