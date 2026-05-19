import SwiftUI

struct NoxPresenceBadgeView: View {
    let state: NoxPresenceState
    var sessionSummary: String?
    var semanticHint: String?
    var capabilities: NoxCapabilityState?

    var body: some View {
        HStack(alignment: .top, spacing: NoxSpacing.md) {
            Image(systemName: state.symbolName)
                .font(.system(size: NoxDesignTokens.SymbolSize.lg, weight: .medium))
                .foregroundStyle(indicatorColor)
                .symbolRenderingMode(.hierarchical)
                .frame(width: NoxDesignTokens.SymbolSize.lg + 4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: NoxSpacing.xs) {
                Text(state.title)
                    .font(NoxTypography.actionEmphasis)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)

                Text(state.description(sessionSummary: sessionSummary, capabilities: capabilities))
                    .font(NoxTypography.caption)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let semanticHint, !semanticHint.isEmpty {
                    Text(semanticHint)
                        .font(NoxTypography.caption)
                        .foregroundStyle(NoxDesignTokens.ColorRole.accent.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(state.title). \(state.description(sessionSummary: sessionSummary, capabilities: capabilities))"
        )
        .accessibilityHint(state.accessibilityHint)
    }

    private var indicatorColor: Color {
        switch state {
        case .limited, .quiet, .resting, .idle:
            NoxDesignTokens.ColorRole.presenceMuted
        case .active, .distracted:
            NoxDesignTokens.ColorRole.presenceActive
        case .focused, .flow:
            NoxDesignTokens.ColorRole.accent
        }
    }
}

#Preview {
    NoxPresenceBadgeView(state: .quiet)
        .padding()
        .frame(width: NoxSpacing.menuBarWidth)
}
