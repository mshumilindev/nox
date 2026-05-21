import SwiftUI
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore

/// Horizontal semantic navigation for compact window mode.
struct NoxCompactNavigationBar: View {
    @Environment(AppEnvironment.self) private var environment

    private var visibleDestinations: [NoxSemanticDestination] {
        NoxSemanticDestination.compactRailOrder.filter {
            environment.showsDestinationInNavigation($0)
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NoxSpacing.xs) {
                ForEach(visibleDestinations) { destination in
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
        let isEcology = destination == .memory
        return Button {
            environment.setNavigationDestination(destination)
        } label: {
            VStack(spacing: 3) {
                NoxIcon(
                    systemName: environment.navigationSymbolName(for: destination),
                    role: .rail,
                    emphasized: selected,
                    tint: isEcology && !selected
                        ? NoxDesignTokens.ColorRole.textSecondary.opacity(0.55)
                        : nil
                )
                Text(environment.navigationTitle(for: destination))
                    .font(NoxTypography.metadata)
                    .lineLimit(1)
                if let hint = environment.navigationSecondaryHint(for: destination) {
                    Text(hint)
                        .font(.system(size: 9))
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.5))
                        .lineLimit(1)
                }
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
            .noxHitTarget(minHeight: isEcology ? 48 : 44)
        }
        .buttonStyle(.noxBorderless(hover: .chip, isSelected: selected))
    }
}
