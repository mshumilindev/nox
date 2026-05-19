import SwiftUI

struct NoxThreadsSurfaceView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        NoxSurfacePage {
            NoxPageIntro(
                title: "Continuity topology",
                subtitle: "Threads link repeated context across sessions — not tasks or projects."
            )

            if environment.longHorizonSnapshot.activeThreads.isEmpty {
                emptyLine("Continuity threads appear as patterns repeat across sessions.")
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
