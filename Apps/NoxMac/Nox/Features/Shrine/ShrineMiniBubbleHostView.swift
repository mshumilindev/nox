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

/// SwiftUI face + hover + context menu. Drag is handled by AppKit `ShrineMiniBubbleContainerView`.
struct ShrineMiniBubbleHostView: View {
  @Environment(AppEnvironment.self) private var environment
  @Bindable var controller: ShrineSurfaceController
  @Bindable var visual: OrbyMiniVisualController

  init(controller: ShrineSurfaceController) {
    self.controller = controller
    self.visual = controller.miniVisual
  }

  private var resolvedMood: OrbyMood {
    controller.baseMood(for: environment)
  }

  private var moodInputs: ShrineMoodInputs {
    OrbyMoodResolver.inputs(
      from: environment,
      soundsMuted: controller.soundsMuted,
      recentDismissCount: controller.recentMiniDismissCount
    )
  }

  private var presentation: OrbyMiniVisualPresentation {
    let intensity = OrbyEmotionIntensityResolver.resolve(mood: resolvedMood, input: moodInputs)
    return visual.presentation(resolvedMood: resolvedMood, intensity: intensity)
  }

  var body: some View {
    OrbyFaceView(presentation: presentation)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.clear)
      .contextMenu {
        Button("Open Full Shrine") {
          visual.noteUserInteraction()
          controller.openFull(using: environment)
        }
        Button("Hide Orby") {
          visual.noteUserInteraction()
          controller.recordMiniDismiss()
        }
        Button("Reset Position") {
          visual.noteUserInteraction()
          controller.resetMiniPosition()
        }
        Divider()
        Button(controller.soundsMuted ? "Unmute Orby Sounds" : "Mute Orby Sounds") {
          visual.noteUserInteraction()
          controller.toggleSoundsMuted()
        }
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel("Orby")
      .accessibilityValue(accessibilityPhaseLabel)
      .accessibilityHint("Click to open Full Shrine. Drag to move Orby.")
  }

  private var accessibilityPhaseLabel: String {
    switch presentation.phase {
    case .asleep:
      "Asleep"
    case .sleepyTransition:
      "Getting sleepy"
    case .hoverExcited:
      "Excited"
    case .dragging:
      "Dragging"
    case .postDragDazed:
      "Settling"
    case .launchGreeting:
      "Saying hello"
    default:
      presentation.resolvedMood.displayTitle
    }
  }
}
