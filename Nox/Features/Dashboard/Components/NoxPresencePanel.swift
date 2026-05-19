import SwiftUI

struct NoxPresencePanel: View {
    let state: NoxPresenceState
    let sessionSummary: String?
    var semanticHint: String?
    var capabilities: NoxCapabilityState?
    var density: Double = 0.45

    @State private var breathe = false

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            sectionHeader("PRESENCE")

            ZStack {
                if state.shouldBreathe {
                    RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                        .fill(NoxDesignTokens.ColorRole.accent.opacity(
                            (breathe ? 0.10 : 0.04) * (0.7 + density * 0.3)
                        ))
                        .animation(
                            .easeInOut(duration: NoxDesignTokens.Animation.breathe).repeatForever(autoreverses: true),
                            value: breathe
                        )
                }

                NoxPresenceBadgeView(
                    state: state,
                    sessionSummary: sessionSummary,
                    semanticHint: semanticHint,
                    capabilities: capabilities
                )
                    .padding(NoxSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(cardBackground)
            .overlay {
                if state.shouldPulse {
                    RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                        .strokeBorder(
                            NoxDesignTokens.ColorRole.accent.opacity(breathe ? 0.35 : 0.12),
                            lineWidth: 1
                        )
                        .animation(
                            .easeInOut(duration: NoxDesignTokens.Animation.pulse).repeatForever(autoreverses: true),
                            value: breathe
                        )
                }
            }
        }
        .onAppear {
            breathe = true
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
            .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(NoxDesignTokens.Opacity.secondary))
            .overlay {
                RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                    .strokeBorder(NoxDesignTokens.ColorRole.border.opacity(NoxDesignTokens.Opacity.divider))
            }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(NoxTypography.sectionLabel)
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            .tracking(0.6)
    }

    private func sectionSubtitle(_ text: String) -> some View {
        Text(text)
            .font(NoxTypography.caption)
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.8))
    }
}

#Preview {
    NoxPresencePanel(state: .quiet, sessionSummary: nil, density: 0.5)
        .padding()
        .frame(width: NoxDesignTokens.Window.width)
}
