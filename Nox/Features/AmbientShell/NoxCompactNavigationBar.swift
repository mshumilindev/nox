import SwiftUI

/// Horizontal semantic navigation for compact window mode.
struct NoxCompactNavigationBar: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NoxSpacing.xs) {
                ForEach(NoxSemanticDestination.allCases) { destination in
                    compactItem(destination)
                }
            }
            .padding(.horizontal, NoxSpacing.md)
        }
        .padding(.vertical, NoxSpacing.sm)
        .background(NoxDesignTokens.ColorRole.rail)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(NoxDesignTokens.ColorRole.border.opacity(0.28))
                .frame(height: 0.5)
                .allowsHitTesting(false)
        }
    }

    private func compactItem(_ destination: NoxSemanticDestination) -> some View {
        let selected = environment.preferences.navigationDestination == destination
        return Button {
            environment.setNavigationDestination(destination)
        } label: {
            VStack(spacing: NoxSpacing.xxs) {
                NoxIcon(
                    systemName: destination.symbolName,
                    role: .rail,
                    emphasized: selected
                )
                Text(destination.title)
                    .font(NoxTypography.metadata)
                    .lineLimit(1)
            }
            .padding(.horizontal, NoxSpacing.sm)
            .padding(.vertical, NoxSpacing.xs)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
                        .fill(NoxDesignTokens.ColorRole.accent.opacity(NoxDesignTokens.Opacity.selectionFill))
                        .overlay(
                            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
                                .strokeBorder(
                                    NoxDesignTokens.ColorRole.accent.opacity(NoxDesignTokens.Opacity.selectionStroke),
                                    lineWidth: 0.5
                                )
                        )
                        .allowsHitTesting(false)
                }
            }
            .noxHitTarget(minHeight: 44)
        }
        .buttonStyle(.noxBorderless)
    }
}
