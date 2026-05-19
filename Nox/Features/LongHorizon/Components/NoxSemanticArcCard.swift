import SwiftUI

struct NoxSemanticArcCard: View {
    let arc: NoxSemanticArc

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xs) {
            HStack {
                Text(arc.label)
                    .font(NoxTypography.actionEmphasis)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)
                Spacer()
                Text(arc.continuityState.rawValue.capitalized)
                    .font(NoxTypography.caption)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            }

            if let detail = arc.detailLine {
                Text(detail)
                    .font(NoxTypography.caption)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            }

            Text(evolutionLine)
                .font(NoxTypography.caption)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.88))
        }
        .padding(NoxSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var evolutionLine: String {
        "\(arc.spanCount) spans · \(arc.evolution.rawValue)"
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
            .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(NoxDesignTokens.Opacity.subtle))
    }
}
