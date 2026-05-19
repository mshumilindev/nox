import SwiftUI

struct NoxEraSurface: View {
    let candidates: [NoxTypedMemoryEntity]

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            ForEach(candidates) { entity in
                VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
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
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
            .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(NoxDesignTokens.Opacity.subtle))
    }
}
