import SwiftUI

struct NoxBehavioralRhythmCard: View {
    let entity: NoxTypedMemoryEntity

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xs) {
            Text(entity.title)
                .font(NoxTypography.actionEmphasis)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)

            Text(entity.summary)
                .font(NoxTypography.caption)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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
