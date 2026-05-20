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

struct NoxMenuBarView: View {
    @Environment(AppEnvironment.self) private var environment

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

    private var atmosphericState: NoxAtmosphericState {
        .night
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
                .strokeBorder(NoxDesignTokens.ColorRole.border.opacity(0.48), lineWidth: 0.5)
        }
        .shadow(
            color: .black.opacity(NoxDesignTokens.Shadow.menuBarOpacity),
            radius: NoxDesignTokens.Shadow.menuBarRadius,
            y: NoxDesignTokens.Shadow.menuBarYOffset
        )
        .preferredColorScheme(.dark)
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

            VStack(alignment: .leading, spacing: NoxSpacing.xs) {
                NoxPresenceBadgeView(
                    state: environment.presence,
                    sessionSummary: environment.sessionSummary,
                    semanticHint: showSemanticHint ? environment.semanticHint : nil,
                    capabilities: environment.capabilities
                )

                if let hint = environment.systemTrayHint, !hint.isEmpty {
                    Text(hint)
                        .noxMetadata()
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(NoxSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                    .fill(NoxDesignTokens.ColorRole.surfaceElevated)
            )
        }
    }

    private var panelBackground: some View {
        ZStack {
            NoxAtmosphereBackground(
                density: environment.memoryDensity * 0.42,
                state: atmosphericState,
                presentation: .menuBar
            )
            NoxDesignTokens.ColorRole.surface.opacity(0.58)
        }
    }
}

#Preview {
    NoxMenuBarView()
        .environment(AppEnvironment())
        .environment(NoxPanelState())
        .padding()
}
