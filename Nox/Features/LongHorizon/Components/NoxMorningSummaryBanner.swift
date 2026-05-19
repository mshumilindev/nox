import SwiftUI

struct NoxMorningSummaryBanner: View {
    let summary: NoxMorningSummary

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            Text(summary.headline)
                .font(NoxTypography.body)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(summary.supportingLines, id: \.self) { line in
                Text(line)
                    .font(NoxTypography.caption)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(NoxSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
            .fill(NoxDesignTokens.ColorRole.accent.opacity(0.08))
            .overlay {
                RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                    .strokeBorder(NoxDesignTokens.ColorRole.border.opacity(NoxDesignTokens.Opacity.divider))
            }
    }
}
