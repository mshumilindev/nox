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

/// Deep window mode — calm reflective observations only.
struct NoxDeepReflectionSurfaceView: View {
    @Environment(AppEnvironment.self) private var environment

    private var snapshot: NoxLongHorizonSnapshot {
        environment.longHorizonSnapshot
    }

    var body: some View {
        NoxSurfacePage {
            header

            if !snapshot.reflections.isEmpty {
                reflectionStream
            }

            if !snapshot.longHorizonNarratives.isEmpty {
                horizonNarratives
            }

            if isSparse {
                sparseState
            }
        }
    }

    private var isSparse: Bool {
        snapshot.reflections.isEmpty && snapshot.longHorizonNarratives.isEmpty
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            Text("Reflection overview")
                .noxPageTitle()
            Text("Patterns summarized from recent memory and activity over time.")
                .font(NoxTypography.reflectionSoft)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(NoxDesignTokens.Opacity.secondary))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var reflectionStream: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            NoxSectionHeader(title: "Reflections", symbol: "text.quote")
            ForEach(snapshot.reflections) { reflection in
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

    private var horizonNarratives: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            NoxSectionHeader(title: "Long-term memory", symbol: "clock.arrow.circlepath")
            ForEach(snapshot.longHorizonNarratives) { narrative in
                VStack(alignment: .leading, spacing: NoxSpacing.xs) {
                    Text(narrative.horizonLabel)
                        .noxMetadata()
                    Text(narrative.summary)
                        .font(NoxTypography.continuityDetail)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .noxSurface(.standard)
            }
        }
    }

    private var sparseState: some View {
        Text("Reflections appear when repeated patterns stabilize. They summarize activity — not advice.")
            .font(NoxTypography.reflectionSoft)
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(NoxDesignTokens.Opacity.secondary))
            .noxSurface(.inset, padding: NoxMaterials.cardPaddingLoose)
    }
}
