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

struct NoxThreadsSurfaceView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        NoxSurfacePage {
            NoxPageIntro(
                title: "Recurring activity patterns",
                subtitle: "Threads connect repeated activity across sessions — not tasks or projects."
            )

            if environment.longHorizonSnapshot.activeThreads.isEmpty {
                emptyLine("Recurring threads appear as activity repeats across sessions.")
            } else {
                NoxCollapsibleSection(
                    title: "Active threads",
                    subtitle: "\(environment.longHorizonSnapshot.activeThreads.count) threads",
                    defaultExpanded: true
                ) {
                    ForEach(environment.longHorizonSnapshot.activeThreads) { thread in
                        VStack(alignment: .leading, spacing: NoxSpacing.md) {
                            NoxContinuityThreadCard(
                                thread: thread,
                                evolution: environment.memoryEvolutionSnapshot
                            )
                            NoxContextExplanationCard(
                                reason: NoxExplainabilityPresenter.whyContinuityAppeared(thread: thread)
                            )
                        }
                    }
                }
            }
        }
    }

    private func emptyLine(_ text: String) -> some View {
        Text(text)
            .font(NoxTypography.reflectionSoft)
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(NoxDesignTokens.Opacity.secondary))
            .noxSurface(.inset, padding: NoxMaterials.cardPaddingLoose)
    }
}
