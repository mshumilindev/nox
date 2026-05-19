import SwiftUI

struct NoxContinuityThreadCard: View {
    let thread: NoxContinuityThread

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xs) {
            Text(NoxContinuityResurfacingPresenter.threadDisplayTitle(thread))
                .font(NoxTypography.actionEmphasis)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)

            Text(NoxContinuityResurfacingPresenter.threadDetailLine(thread))
                .font(NoxTypography.caption)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
        }
        .padding(NoxSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
            .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(NoxDesignTokens.Opacity.subtle))
    }
}
