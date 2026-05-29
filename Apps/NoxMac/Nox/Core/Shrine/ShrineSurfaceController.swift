import Foundation
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
import Observation

/// Coordinates Software Shrine surfaces (mini bubble + full placeholder). Does not own dashboard or menu bar.
@MainActor
@Observable
final class ShrineSurfaceController {
  let miniPanel = ShrineMiniPanelController()
  let fullWindow = ShrineFullWindowController()
  let miniVisual = OrbyMiniVisualController()

  private(set) var soundsMuted = false
  private(set) var recentMiniDismissCount = 0
  private weak var environment: AppEnvironment?

  var isMiniVisible: Bool { miniPanel.isVisible }

  func install(environment: AppEnvironment) {
    self.environment = environment
    miniPanel.bind(environment: environment, surfaceController: self)
  }

  func showMini() {
    showMiniAtDefaultPosition()
  }

  /// Menu toggle: show uses default bottom-right placement; hide preserves last drag position in store.
  func toggleMini() {
    if isMiniVisible {
      hideMini()
    } else {
      showMiniAtDefaultPosition()
    }
  }

  func showMiniAtDefaultPosition() {
    miniPanel.showAtDefaultPosition()
    miniVisual.noteShow(playLaunchGreeting: true)
  }

  func hideMini() {
    miniPanel.hide()
    miniVisual.noteHide()
  }

  func resetMiniPosition() {
    miniVisual.noteUserInteraction()
    miniPanel.resetPosition()
  }

  func openFull(using environment: AppEnvironment) {
    miniVisual.noteUserInteraction()
    fullWindow.openOrFocus(using: environment, surfaceController: self)
  }

  func closeFull() {
    fullWindow.close()
  }

  func recordMiniDismiss() {
    recentMiniDismissCount += 1
    hideMini()
  }

  func toggleSoundsMuted() {
    soundsMuted.toggle()
  }

  /// Deterministic mood only — hover/sleep/wake are visual overrides in `miniVisual`.
  func baseMood(for environment: AppEnvironment) -> ShrineMiniMood {
    let input = ShrineMoodResolver.inputs(
      from: environment,
      soundsMuted: soundsMuted,
      recentDismissCount: recentMiniDismissCount
    )
    return ShrineMoodResolver.resolve(input)
  }
}
