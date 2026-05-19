import SwiftUI

struct NoxContinuityThreadCard: View {
  let thread: NoxContinuityThread

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.xs) {
      Text(NoxContinuityResurfacingPresenter.threadDisplayTitle(thread))
        .font(NoxTypography.continuity)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.92))

      Text(NoxContinuityResurfacingPresenter.threadDetailLine(thread))
        .noxMetadata()
    }
    .noxSurface(.standard)
  }
}
