import SwiftUI

struct NoxDashboardView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: NoxSpacing.section) {
                NoxDashboardHeader(presence: environment.presence)
                VStack(alignment: .leading, spacing: NoxSpacing.xl) {
                NoxPresencePanel(
                    state: environment.presence,
                    sessionSummary: environment.sessionSummary,
                    semanticHint: environment.semanticHint,
                    capabilities: environment.capabilities,
                    density: environment.memoryDensity
                )
                    NoxLiveSignalsView(signals: environment.liveSignals)
                }

                NoxLongHorizonView(
                    snapshot: environment.longHorizonSnapshot,
                    morningSummary: environment.morningSummary
                )

                VStack(alignment: .leading, spacing: NoxSpacing.lg) {
                    NoxMemoryPeriodPicker()
                    NoxMemorySearchField()
                    NoxMemoryTimelineView(
                        blocks: environment.timelineBlocks,
                        emergence: environment.memoryEmergence,
                        density: environment.memoryDensity,
                        dayOverview: environment.memoryPeriod == .today
                            ? environment.daySemanticOverview
                            : nil,
                        presence: environment.presence
                    )
                }

                NoxSystemStatusView()

                #if DEBUG
                NoxContextExplainabilityView(snapshot: environment.contextDebugSnapshot)
                #endif

                NoxPhilosophySurface(
                    presence: environment.presence,
                    style: .footer
                )
            }
            .padding(NoxSpacing.xl)
        }
        .frame(
            width: NoxDesignTokens.Window.width,
            height: NoxDesignTokens.Window.height
        )
        .background(dashboardBackground)
        .preferredColorScheme(colorScheme)
        .task {
            environment.startIfNeeded()
        }
    }

    private var dashboardBackground: some View {
        ZStack {
            NoxDesignTokens.ColorRole.surface
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.9 + environment.memoryDensity * 0.08)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NoxDashboardView()
        .environment(AppEnvironment())
}
