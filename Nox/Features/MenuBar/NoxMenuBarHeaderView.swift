import SwiftUI

struct NoxMenuBarHeaderView: View {
    var body: some View {
        HStack(alignment: .center, spacing: NoxSpacing.md) {
            Image("NoxTriskelionMark")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: NoxDesignTokens.SymbolSize.brand + 4, height: NoxDesignTokens.SymbolSize.brand + 4)
                .foregroundStyle(NoxDesignTokens.ColorRole.accent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
                Text("Nox")
                    .font(NoxTypography.wordmark)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)

                Text("Local activity memory")
                    .font(NoxTypography.tagline)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nox, local activity memory")
    }
}

#Preview {
    NoxMenuBarHeaderView()
        .padding()
        .frame(width: NoxSpacing.menuBarWidth)
}
