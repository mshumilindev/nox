import SwiftUI

struct NoxMenuBarHeaderView: View {
    var body: some View {
        HStack(alignment: .center, spacing: NoxSpacing.md) {
            Image(systemName: NoxDesignTokens.Icon.brandSymbol)
                .font(.system(size: NoxDesignTokens.SymbolSize.brand, weight: .medium))
                .foregroundStyle(NoxDesignTokens.ColorRole.accent)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
                Text("Nox")
                    .font(NoxTypography.wordmark)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)

                Text("Quiet contextual memory")
                    .font(NoxTypography.tagline)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nox, quiet contextual memory")
    }
}

#Preview {
    NoxMenuBarHeaderView()
        .padding()
        .frame(width: NoxSpacing.menuBarWidth)
}
