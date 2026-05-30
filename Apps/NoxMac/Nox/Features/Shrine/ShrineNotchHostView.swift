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

/// Compact Orby inside the fake Dynamic Notch capsule.
struct ShrineNotchHostView: View {
  @Environment(AppEnvironment.self) private var environment
  @Bindable var controller: ShrineSurfaceController
  @Bindable var visual: OrbyMiniVisualController
  let docking: OrbyNotchDockingController
  let showsOrby: Bool

  init(controller: ShrineSurfaceController, docking: OrbyNotchDockingController, showsOrby: Bool) {
    self.controller = controller
    self.visual = controller.miniVisual
    self.docking = docking
    self.showsOrby = showsOrby
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

  private var orbyDiameter: CGFloat { OrbyNotchDockingMetrics.notchOrbyDiameter }

  var body: some View {
    ZStack(alignment: .top) {
      OrbyFakeNotchCapsuleView(
        state: docking.fakeNotchVisualState,
        notchSize: docking.fakeNotchFrameSize,
        widthFraction: docking.fakeNotchWidthFraction
      )

      if showsOrby {
        OrbyFaceView(presentation: presentation)
          .frame(width: orbyDiameter, height: orbyDiameter)
          .offset(
            x: docking.orbyXOffsetInCapsule + visual.notchPullVisualOffset.width + visual.notchUndockTrembleOffset.width,
            y: visual.notchPullVisualOffset.height
          )
          .padding(.top, (docking.fakeNotchFrameSize.height - orbyDiameter) / 2)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.clear)
    .contextMenu {
      if showsOrby {
        Button("Open Full Shrine") {
          visual.noteUserInteraction()
          controller.openFull(using: environment)
        }
        Button("Hide Orby") {
          visual.noteUserInteraction()
          controller.recordMiniDismiss()
        }
        Divider()
        Button(controller.soundsMuted ? "Unmute Orby Sounds" : "Mute Orby Sounds") {
          visual.noteUserInteraction()
          controller.toggleSoundsMuted()
        }
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Orby")
    .accessibilityHint(
      showsOrby
        ? "Drag to pull Orby out of the notch. Click to open Full Shrine."
        : "Dock target for Orby near the MacBook notch."
    )
  }
}
