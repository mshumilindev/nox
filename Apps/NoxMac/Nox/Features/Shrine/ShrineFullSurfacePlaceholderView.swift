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
import NoxShrineCore

struct ShrineFullSurfacePlaceholderView: View {
  @Environment(AppEnvironment.self) private var environment
  @Bindable var surfaceController: ShrineSurfaceController

  private var presentation: ShrineMiniVisualPresentation {
    let mood = surfaceController.baseMood(for: environment)
    let input = OrbyMoodResolver.inputs(
      from: environment,
      soundsMuted: surfaceController.soundsMuted,
      recentDismissCount: surfaceController.recentMiniDismissCount
    )
    let intensity = OrbyEmotionIntensityResolver.resolve(mood: mood, input: input)
    return surfaceController.miniVisual.presentation(resolvedMood: mood, intensity: intensity)
  }

  var body: some View {
    VStack(spacing: NoxSpacing.lg) {
      Text("Nox Shrine")
        .font(NoxTypography.surfaceTitle)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)

      OrbyFaceView(presentation: presentation)
        .scaleEffect(1.6)
        .padding(.vertical, NoxSpacing.md)

      Text("Current mood: \(presentation.resolvedMood.displayTitle)")
        .font(NoxTypography.caption)
        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)

      if let label = environment.activeContextLabel, !label.isEmpty {
        Text(label)
          .font(NoxTypography.caption)
          .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
          .multilineTextAlignment(.center)
      }

      VStack(spacing: NoxSpacing.sm) {
        Button("Hide Mini Shrine") {
          surfaceController.recordMiniDismiss()
        }
        Button("Reset Position") {
          surfaceController.resetMiniPosition()
        }
        Button("Close") {
          surfaceController.closeFull()
        }
      }
      .buttonStyle(.bordered)
    }
    .padding(NoxSpacing.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(NoxDesignTokens.ColorRole.canvas)
  }
}
