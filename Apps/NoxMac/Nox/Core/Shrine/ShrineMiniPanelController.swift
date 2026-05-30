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
final class ShrineMiniPanelController: NSObject, NSWindowDelegate {
  private var panel: NSPanel?
  private var hostingController: NSHostingController<AnyView>?
  private var containerView: ShrineMiniBubbleContainerView?
  private var isApplyingFrame = false

  let positionStore = ShrinePositionStore()

  private weak var environment: AppEnvironment?
  private weak var surfaceController: ShrineSurfaceController?
  weak var notchDocking: OrbyNotchDockingController?

  /// Transparent margin so inner ground shadow is never clipped by the panel.
  private let chromeMargin: CGFloat = OrbyOrbGeometry.chromePadding
  private let orbDiameter: CGFloat = OrbyOrbGeometry.orbDiameter
  private var bubbleVisualSize: CGFloat { orbDiameter + chromeMargin * 2 }

  var isVisible: Bool { panel?.isVisible == true }

  var panelSize: CGSize {
    let side = bubbleVisualSize + chromeMargin * 2
    return CGSize(width: side, height: side)
  }

  var currentOrigin: CGPoint? { panel?.frame.origin }

  func bind(environment: AppEnvironment, surfaceController: ShrineSurfaceController) {
    self.environment = environment
    self.surfaceController = surfaceController
  }

  func show() {
    buildIfNeeded()
    guard let panel, let surfaceController else { return }
    surfaceController.miniVisual.attach(panel: panel)
    placeOnPreferredScreen(animated: false)
    panel.orderFrontRegardless()
    surfaceController.miniVisual.start()
  }

  /// Show at the default bottom-right placement (same origin as Reset Position).
  func showAtDefaultPosition() {
    buildIfNeeded()
    guard let panel, let surfaceController else { return }
    surfaceController.miniVisual.attach(panel: panel)
    let screen = positionStore.mainScreen()
    let origin = positionStore.reset(on: screen, panelSize: panelSize)
    applyFrame(origin: origin, on: screen, animate: false)
    panel.orderFrontRegardless()
    surfaceController.miniVisual.start()
  }

  /// Shows the bubble panel without changing placement (used after notch undock).
  func showWithoutDefaultPlacement() {
    buildIfNeeded()
    guard let panel, let surfaceController else { return }
    surfaceController.miniVisual.attach(panel: panel)
    panel.orderFrontRegardless()
    surfaceController.miniVisual.start()
  }

  func persistCurrentOrigin() {
    guard let panel, let screen = panel.screen ?? NSScreen.main else { return }
    positionStore.save(origin: panel.frame.origin, for: screen)
  }

  func hide() {
    surfaceController?.miniVisual.stop()
    panel?.orderOut(nil)
  }

  func resetPosition() {
    guard let panel else { return }
    let screen = positionStore.screen(containing: panel.frame)
    let origin = positionStore.reset(on: screen, panelSize: panelSize)
    applyFrame(origin: origin, on: screen, animate: true)
  }

  func beginUserDrag() {
    notchDocking?.noteBubbleDragBegan()
    surfaceController?.miniVisual.beginDrag()
    // Raise panel above the notch panel so bubble renders on top during drag.
    panel?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 4)
  }

  func noteDragStep(screenDelta: CGSize, sampleTime: Date, totalDistance: CGFloat) {
    surfaceController?.miniVisual.noteDragStep(
      screenDelta: screenDelta,
      sampleTime: sampleTime,
      totalDistance: totalDistance
    )
  }

  func noteBubbleDrag(orbCenter: NSPoint, mouse: NSPoint) {
    notchDocking?.noteBubbleDrag(orbCenter: orbCenter, mouse: mouse)
  }

  func endUserDrag(metrics: OrbyDragGestureMetrics, orbCenter: NSPoint, cursor: NSPoint) {
    notchDocking?.endBubbleDrag(orbCenter: orbCenter, cursor: cursor, metrics: metrics)
    // Restore normal level after drag.
    panel?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
    if notchDocking?.isDockedInNotch != true {
      snapToVisibleFrameIfNeeded(animated: true)
    }
  }

  func noteContextMenuOpened() {
    surfaceController?.miniVisual.noteContextMenuOpened()
  }

  func setFrameOrigin(_ origin: NSPoint, persist: Bool, cursor: NSPoint? = nil) {
    guard let panel else { return }
    let screen = positionStore.screen(containing: NSRect(origin: origin, size: panel.frame.size))
    let clamped = clampedOrigin(
      origin,
      on: screen,
      cursor: cursor ?? NSEvent.mouseLocation
    )
    applyFrame(origin: clamped, on: screen, animate: false, originAlreadyClamped: true)
    if persist {
      positionStore.save(origin: clamped, for: screen)
    }
  }

  /// True when any part of the bubble panel sits outside the screen's safe visible area.
  func isOutsideVisibleFrame() -> Bool {
    guard let panel else { return false }
    let screen = positionStore.screen(containing: panel.frame)
    return !NoxShrineMiniBubblePlacement.isFullyVisible(
      origin: ShrineScreenGeometry.point(panel.frame.origin),
      panelSize: ShrineScreenGeometry.panelSize(panelSize),
      visibleFrame: ShrineScreenGeometry.screenRect(screen.visibleFrame)
    )
  }

  /// Snaps Bubble Orby to the nearest origin fully inside `visibleFrame`. Returns whether a move occurred.
  @discardableResult
  func snapToVisibleFrameIfNeeded(animated: Bool) -> Bool {
    guard let panel else { return false }
    let screen = positionStore.screen(containing: panel.frame)
    let clamped = clampedOrigin(
      panel.frame.origin,
      on: screen,
      cursor: nil,
      forceNormal: true
    )
    guard clamped != panel.frame.origin else { return false }
    applyFrame(origin: clamped, on: screen, animate: animated)
    positionStore.save(origin: clamped, for: screen)
    return true
  }

  /// Returns Bubble to the normal visibleFrame after a failed notch docking attempt.
  func clampToVisibleFrame(animated: Bool) {
    snapToVisibleFrameIfNeeded(animated: animated)
  }

  // MARK: - Private

  private func buildIfNeeded() {
    guard panel == nil, let environment, let surfaceController else { return }

    let root = ShrineMiniBubbleHostView(controller: surfaceController)
      .environment(environment)

    let hosting = NSHostingController(rootView: AnyView(root))
    configureHostingView(hosting.view)
    hostingController = hosting

    let container = ShrineMiniBubbleContainerView(
      hostingView: hosting.view,
      panelController: self
    )
    container.onClick = { [weak surfaceController, weak environment] in
      guard let environment, let surfaceController else { return }
      surfaceController.miniVisual.noteUserInteraction()
      surfaceController.openFull(using: environment)
    }
    containerView = container

    let panel = NSPanel(
      contentRect: NSRect(origin: .zero, size: panelSize),
      styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    panel.isFloatingPanel = true
    panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    panel.animationBehavior = .none
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = false
    panel.hidesOnDeactivate = false
    panel.isMovableByWindowBackground = false
    panel.ignoresMouseEvents = false
    panel.becomesKeyOnlyIfNeeded = true
    panel.isReleasedWhenClosed = false
    panel.contentView = container
    panel.delegate = self
    self.panel = panel
  }

  private func configureHostingView(_ view: NSView) {
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.clear.cgColor
    view.layer?.masksToBounds = false
    if #available(macOS 13.0, *), let hosting = view as? NSHostingView<AnyView> {
      hosting.safeAreaRegions = []
    }
  }

  private func placeOnPreferredScreen(animated: Bool) {
    let screen = positionStore.mainScreen()
    let origin = positionStore.resolvedOrigin(for: screen, panelSize: panelSize)
    applyFrame(origin: origin, on: screen, animate: animated)
  }

  private func clampedOrigin(
    _ origin: NSPoint,
    on screen: NSScreen,
    cursor: NSPoint?,
    forceNormal: Bool = false
  ) -> NSPoint {
    let clampMode: NoxShrineMiniBubblePlacement.ClampMode
    if !forceNormal,
       surfaceController?.miniVisual.isDragging == true,
       let cursor {
      let inCorridor = OrbyNotchGeometry.isCursorInNotchCaptureCorridor(cursor: cursor, on: screen)
      clampMode = inCorridor ? .notchDocking : .normalBubble
    } else {
      clampMode = .normalBubble
    }

    let notchAnchorY: CGFloat? = clampMode == .notchDocking
      ? notchDocking?.notchAnchorY(for: screen)
      : nil

    let clampedPoint = NoxShrineMiniBubblePlacement.clamp(
      origin: ShrineScreenGeometry.point(origin),
      panelSize: ShrineScreenGeometry.panelSize(panelSize),
      mode: clampMode,
      screenFrame: ShrineScreenGeometry.screenRect(screen.frame),
      visibleFrame: ShrineScreenGeometry.screenRect(screen.visibleFrame),
      topMargin: 0,
      notchAnchorY: notchAnchorY
    )
    return ShrineScreenGeometry.cgPoint(clampedPoint)
  }

  private func applyFrame(
    origin: CGPoint,
    on screen: NSScreen,
    animate: Bool,
    originAlreadyClamped: Bool = false
  ) {
    guard let panel else { return }
    var frame = panel.frame
    frame.size = panelSize
    if originAlreadyClamped {
      frame.origin = origin
    } else {
      frame.origin = clampedOrigin(origin, on: screen, cursor: nil, forceNormal: true)
    }
    isApplyingFrame = true
    panel.setFrame(frame, display: true, animate: animate)
    isApplyingFrame = false
  }

  func windowDidMove(_ notification: Notification) {
    guard !isApplyingFrame,
          surfaceController?.miniVisual.isDragging != true,
          let panel = notification.object as? NSPanel else { return }
    let screen = positionStore.screen(containing: panel.frame)
    let clamped = clampedOrigin(panel.frame.origin, on: screen, cursor: nil, forceNormal: true)
    if clamped != panel.frame.origin {
      applyFrame(origin: clamped, on: screen, animate: false)
    }
    positionStore.save(origin: panel.frame.origin, for: screen)
  }
}
