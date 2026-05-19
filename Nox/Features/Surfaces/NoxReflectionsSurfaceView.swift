import SwiftUI

struct NoxReflectionsSurfaceView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        NoxSurfacePage {
            NoxSectionHeader(
                title: "Reflections",
                symbol: "text.quote",
                subtitle: "Calm observations from local memory — not advice."
            )

            if environment.longHorizonSnapshot.reflections.isEmpty {
                Text("Reflections appear infrequently when patterns stabilize.")
                    .font(NoxTypography.reflectionSoft)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(NoxDesignTokens.Opacity.secondary))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .noxSurface(.major)
            } else {
                VStack(alignment: .leading, spacing: NoxSpacing.cardStack) {
                    ForEach(environment.longHorizonSnapshot.reflections) { reflection in
                        let reason = NoxExplainabilityPresenter.whyReflectionAppeared(reflection)
                        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
                            Text(reason.headline)
                                .font(NoxTypography.reflection)
                                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.94))
                                .fixedSize(horizontal: false, vertical: true)
                            if let detail = reason.detail {
                                Text(detail)
                                    .noxMetadata()
                            }
                        }
                        .noxSurface(.major)
                    }
                }
            }
        }
    }
}
