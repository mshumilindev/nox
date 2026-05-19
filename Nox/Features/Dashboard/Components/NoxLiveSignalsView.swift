import SwiftUI

struct NoxLiveSignalsView: View {
    @Environment(AppEnvironment.self) private var environment
    let signals: [NoxLiveSignal]
    var compact: Bool = false

    private var presentation: NoxLiveContextPresentation {
        NoxLiveContextPresenter.present(
            signals: signals,
            semanticContext: environment.semanticInference,
            contextLabel: environment.activeContextLabel,
            compact: compact
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            sectionHeader(compact ? "LIVE" : "LIVE CONTEXT")

            if presentation.isEmpty {
                placeholderRow
            } else {
                VStack(alignment: .leading, spacing: compact ? NoxSpacing.md : NoxSpacing.lg) {
                    if !presentation.pulse.isEmpty {
                        pulseSection
                    }
                    if !presentation.detail.isEmpty {
                        detailSection
                    }
                }
                .padding(compact ? NoxSpacing.md : NoxSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
            }
        }
    }

    private var pulseSection: some View {
        VStack(alignment: .leading, spacing: compact ? NoxSpacing.xs : NoxSpacing.sm) {
            ForEach(presentation.pulse) { item in
                HStack(alignment: .firstTextBaseline, spacing: NoxSpacing.sm) {
                    if !compact {
                        Text(item.timestamp, style: .time)
                            .font(NoxTypography.timelineTime)
                            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.7))
                            .frame(width: 48, alignment: .leading)
                    }

                    Image(systemName: item.symbolName)
                        .font(.system(size: compact ? 12 : 13, weight: .semibold))
                        .foregroundStyle(NoxDesignTokens.ColorRole.accent.opacity(0.85))
                        .frame(width: 18, alignment: .center)

                    Text(item.text)
                        .font(compact ? NoxTypography.actionEmphasis : NoxTypography.body)
                        .fontWeight(.medium)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.94))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xs) {
            ForEach(presentation.detail) { item in
                HStack(alignment: .firstTextBaseline, spacing: NoxSpacing.xs) {
                    Image(systemName: item.symbolName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.56))
                        .frame(width: 14, alignment: .center)

                    Text(item.text)
                        .font(NoxTypography.caption)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.leading, compact ? 0 : NoxSpacing.xs + 48)
    }

    private var placeholderRow: some View {
        HStack(spacing: NoxSpacing.sm) {
            Circle()
                .fill(NoxDesignTokens.ColorRole.presenceActive)
                .frame(width: 5, height: 5)
                .opacity(0.7)
            Text("Quiet for now")
                .font(NoxTypography.caption)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
        }
        .padding(NoxSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
            .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(0.38))
            .overlay {
                RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                    .strokeBorder(
                        NoxDesignTokens.ColorRole.border.opacity(NoxDesignTokens.Opacity.divider * 0.65)
                    )
            }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(NoxTypography.sectionLabel)
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            .tracking(0.6)
    }
}

#Preview {
    NoxLiveSignalsView(signals: [
        NoxLiveSignal(
            id: "semantic-1",
            timestamp: Date(),
            text: "Fragmented attention period",
            kind: .awareness
        ),
        NoxLiveSignal(
            id: "app-1",
            timestamp: Date(),
            text: "Switched to ChatGPT",
            kind: .app
        ),
        NoxLiveSignal(
            id: "app-2",
            timestamp: Date().addingTimeInterval(-30),
            text: "Switched to Cursor",
            kind: .app
        )
    ])
    .environment(AppEnvironment())
    .padding()
    .frame(width: NoxDesignTokens.Window.width)
}
