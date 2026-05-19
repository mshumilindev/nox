import SwiftUI

struct NoxMenuBarView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.colorScheme) private var colorScheme

    private var presentation: NoxLiveContextPresentation {
        NoxLiveContextPresenter.present(
            signals: environment.liveSignals,
            semanticContext: environment.semanticInference,
            contextLabel: environment.activeContextLabel,
            compact: true
        )
    }

    private var showSemanticHint: Bool {
        guard let hint = environment.semanticHint, !hint.isEmpty else { return false }
        let pulseTexts = presentation.pulse.map { $0.text.lowercased() }
        return !pulseTexts.contains(where: { $0.contains(hint.lowercased()) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xl) {
            NoxMenuBarHeaderView()

            presenceSection

            if !presentation.isEmpty {
                NoxLiveSignalsView(signals: environment.liveSignals, compact: true)
            }

            NoxMenuBarActionsView()

            NoxPhilosophySurface(
                presence: environment.presence,
                style: .compact,
                showsLocalNote: false
            )
        }
        .padding(NoxSpacing.lg)
        .frame(width: NoxSpacing.menuBarWidth)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.lg, style: .continuous)
                .strokeBorder(NoxDesignTokens.ColorRole.border, lineWidth: 1)
        }
        .shadow(
            color: .black.opacity(NoxDesignTokens.Shadow.menuBarOpacity),
            radius: NoxDesignTokens.Shadow.menuBarRadius,
            y: NoxDesignTokens.Shadow.menuBarYOffset
        )
        .preferredColorScheme(colorScheme)
        .task {
            environment.startIfNeeded()
        }
    }

    private var presenceSection: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            Text("NOW")
                .font(NoxTypography.sectionLabel)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                .tracking(0.6)

            NoxPresenceBadgeView(
                state: environment.presence,
                sessionSummary: environment.sessionSummary,
                semanticHint: showSemanticHint ? environment.semanticHint : nil,
                capabilities: environment.capabilities
            )
            .padding(NoxSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                    .fill(NoxDesignTokens.ColorRole.surfaceElevated)
            )
        }
    }

    private var panelBackground: some View {
        NoxDesignTokens.ColorRole.surface
    }
}

#Preview {
    NoxMenuBarView()
        .environment(AppEnvironment())
        .environment(NoxPanelState())
        .padding()
}
