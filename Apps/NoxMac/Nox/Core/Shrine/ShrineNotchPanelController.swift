import SwiftUI
import AppKit
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

@MainActor
final class ShrineNotchPanelController: NSObject, NSWindowDelegate {
  private var panel: NSPanel?
  private var hostingController: NSHostingController<AnyView>?
  private var containerView: ShrineNotchContainerView?
  private var contentShowsOrby = true

  private weak var environment: AppEnvironment?
  private weak var surfaceController: ShrineSurfaceController?
  private weak var dockingController: OrbyNotchDockingController?

  var isVisible: Bool { panel?.isVisible == true }

  var panelForVisualAttach: NSPanel? { panel }

  func bind(
    environment: AppEnvironment,
    surfaceController: ShrineSurfaceController,
    dockingController: OrbyNotchDockingController
  ) {
    self.environment = environment
    self.surfaceController = surfaceController
    self.dockingController = dockingController
  }

  func showDocked(layout: OrbyNotchLayout, animated: Bool) {
    animTask?.cancel()
    animTask = nil
    hasExtended = false
    buildIfNeeded(showsOrby: true)
    guard let panel, let surfaceController else { return }
    panel.ignoresMouseEvents = false
    panel.contentView?.layer?.masksToBounds = false
    surfaceController.miniVisual.attach(panel: panel)
    // Always snap instantly — never animate frame between modes.
    panel.setFrame(layout.fakeNotchFrame, display: true, animate: false)
    panel.orderFrontRegardless()
    surfaceController.miniVisual.start()
  }

  private var animTask: Task<Void, Never>?
  private var hasExtended = false

  /// Extend the fake notch leftward from the real notch edge (screen center).
  /// The panel stays at the full target frame; SwiftUI clips the capsule width.
  func showPreview(layout: OrbyNotchLayout, animated: Bool) {
    guard !hasExtended else { return }
    hasExtended = true
    animTask?.cancel()
    animTask = nil
    buildIfNeeded(showsOrby: false)
    guard let panel else { return }
    panel.ignoresMouseEvents = true
    panel.contentView?.layer?.masksToBounds = true

    let target = layout.fakeNotchFrame
    panel.setFrame(target, display: true, animate: false)
    panel.orderFrontRegardless()
  }

  /// Shrink the fake notch from left toward right (screen center), then hide.
  func retractAndHide(layout: OrbyNotchLayout) {
    guard let panel else { hide(); return }
    animTask?.cancel()
    hasExtended = false

    let notchFrame = layout.fakeNotchFrame
    panel.contentView?.layer?.masksToBounds = true
    panel.setFrame(notchFrame, display: true, animate: false)

    animTask = Task { @MainActor in
      try? await Task.sleep(nanoseconds: UInt64(OrbyNotchDockingMetrics.fakeNotchCollapseSeconds * 1_000_000_000))
      guard !Task.isCancelled else { return }
      panel.orderOut(nil)
    }
  }

  /// Keep only the fake-notch shell visible while Bubble Orby finishes the undock ritual.
  func showRetractShell(layout: OrbyNotchLayout) {
    animTask?.cancel()
    animTask = nil
    hasExtended = true
    buildIfNeeded(showsOrby: false)
    guard let panel else { return }
    panel.ignoresMouseEvents = true
    panel.contentView?.layer?.masksToBounds = true
    panel.setFrame(layout.fakeNotchFrame, display: true, animate: false)
    panel.orderFrontRegardless()
  }

  func resetPreviewState() {
    hasExtended = false
    animTask?.cancel()
    animTask = nil
  }

  /// Show pulling frame. Keep it pinned to the real fake-notch frame so drag resistance
  /// never makes the notch jump away from the physical notch.
  func showPulling(layout: OrbyNotchLayout, animated: Bool) {
    animTask?.cancel()
    animTask = nil
    buildIfNeeded(showsOrby: true)
    guard let panel else { return }
    panel.ignoresMouseEvents = false
    panel.contentView?.layer?.masksToBounds = false
    panel.setFrame(layout.fakeNotchFrame, display: true, animate: false)
    panel.orderFrontRegardless()
  }

  func hide() {
    hasExtended = false
    animTask?.cancel()
    animTask = nil
    panel?.orderOut(nil)
  }

  func noteContextMenuOpened() {
    surfaceController?.miniVisual.noteContextMenuOpened()
  }

  // MARK: - Private

  private func buildIfNeeded(showsOrby: Bool) {
    if panel != nil {
      rebuildContent(showsOrby: showsOrby)
      return
    }
    guard let environment,
          let surfaceController,
          let dockingController else { return }

    contentShowsOrby = showsOrby
    let container = makeContainer(
      environment: environment,
      surfaceController: surfaceController,
      dockingController: dockingController,
      showsOrby: showsOrby
    )
    containerView = container

    let initialSize = CGSize(
      width: OrbyNotchDockingMetrics.fakeNotchCapsuleWidth,
      height: OrbyNotchDockingMetrics.fakeNotchCapsuleHeight
    )
    let panel = NSPanel(
      contentRect: NSRect(origin: .zero, size: initialSize),
      styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    panel.isFloatingPanel = true
    panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 2)
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    panel.animationBehavior = .none
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = false
    panel.hidesOnDeactivate = false
    panel.ignoresMouseEvents = false
    panel.becomesKeyOnlyIfNeeded = true
    panel.isReleasedWhenClosed = false
    panel.contentView = container
    panel.delegate = self
    self.panel = panel
  }

  private func rebuildContent(showsOrby: Bool) {
    guard contentShowsOrby != showsOrby,
          let panel,
          let environment,
          let surfaceController,
          let dockingController else { return }
    contentShowsOrby = showsOrby
    let container = makeContainer(
      environment: environment,
      surfaceController: surfaceController,
      dockingController: dockingController,
      showsOrby: showsOrby
    )
    panel.contentView = container
    containerView = container
  }

  private func makeContainer(
    environment: AppEnvironment,
    surfaceController: ShrineSurfaceController,
    dockingController: OrbyNotchDockingController,
    showsOrby: Bool
  ) -> ShrineNotchContainerView {
    let root = ShrineNotchHostView(
      controller: surfaceController,
      docking: dockingController,
      showsOrby: showsOrby
    )
    .environment(environment)

    let hosting = NSHostingController(rootView: AnyView(root))
    configureHostingView(hosting.view)
    hostingController = hosting

    let container = ShrineNotchContainerView(
      hostingView: hosting.view,
      dockingController: dockingController
    )
    container.onClick = { [weak surfaceController, weak environment] in
      guard let environment, let surfaceController else { return }
      surfaceController.miniVisual.noteUserInteraction()
      surfaceController.openFull(using: environment)
    }
    return container
  }

  private func configureHostingView(_ view: NSView) {
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.clear.cgColor
    view.layer?.masksToBounds = false
    if #available(macOS 13.0, *), let hosting = view as? NSHostingView<AnyView> {
      hosting.safeAreaRegions = []
    }
  }
}
