import AppKit

/// Clear AppKit container: hosts SwiftUI; drag/click use circular Orby hit targets only.
@MainActor
final class ShrineMiniBubbleContainerView: NSView {
  private let hostingView: NSView
  private weak var panelController: ShrineMiniPanelController?

  private var dragStartMouseScreen: NSPoint?
  private var dragStartWindowOrigin: NSPoint?
  private var dragPreviousMouseScreen: NSPoint?
  private var dragGestureTracker = OrbyDragGestureTracker()
  private var didDrag = false
  private var mouseDownInsideOrb = false

  var onClick: (() -> Void)?

  init(hostingView: NSView, panelController: ShrineMiniPanelController) {
    self.hostingView = hostingView
    self.panelController = panelController
    super.init(frame: .zero)
    wantsLayer = true
    layer?.backgroundColor = .clear
    hostingView.wantsLayer = true
    if let layer = hostingView.layer {
      layer.backgroundColor = NSColor.clear.cgColor
      layer.masksToBounds = false
    }
    addSubview(hostingView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var isOpaque: Bool { false }

  override func layout() {
    super.layout()
    hostingView.frame = bounds
  }

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

  override func mouseDown(with event: NSEvent) {
    mouseDownInsideOrb = isMouseInsideOrb(for: event)
    guard mouseDownInsideOrb, let window else { return }
    let mouse = NSEvent.mouseLocation
    dragStartMouseScreen = mouse
    dragPreviousMouseScreen = mouse
    dragGestureTracker.begin(at: mouse, time: sampleTime(for: event))
    dragStartWindowOrigin = window.frame.origin
    didDrag = false
    panelController?.beginUserDrag()
  }

  override func rightMouseDown(with event: NSEvent) {
    guard isMouseInsideOrb(for: event) else { return }
    panelController?.noteContextMenuOpened()
    hostingView.rightMouseDown(with: event)
  }

  override func mouseDragged(with event: NSEvent) {
    guard mouseDownInsideOrb,
          let panelController,
          let startMouse = dragStartMouseScreen,
          let startOrigin = dragStartWindowOrigin else { return }

    let currentMouse = NSEvent.mouseLocation
    let deltaX = currentMouse.x - startMouse.x
    let deltaY = currentMouse.y - startMouse.y
    if abs(deltaX) > 1.5 || abs(deltaY) > 1.5 {
      didDrag = true
    }

    if let previous = dragPreviousMouseScreen {
      let stepX = currentMouse.x - previous.x
      let stepY = currentMouse.y - previous.y
      dragGestureTracker.addSample(at: currentMouse, time: sampleTime(for: event))
      panelController.noteDragStep(
        screenDelta: CGSize(width: stepX, height: stepY),
        sampleTime: sampleTime(for: event),
        totalDistance: 0
      )
    }
    dragPreviousMouseScreen = currentMouse

    let nextOrigin = NSPoint(
      x: startOrigin.x + deltaX,
      y: startOrigin.y + deltaY
    )
    panelController.setFrameOrigin(nextOrigin, persist: false, cursor: currentMouse)

    if let panel = window as? NSPanel {
      let orbCenter = OrbyOrbGeometry.orbCenterScreen(panel: panel)
      panelController.noteBubbleDrag(orbCenter: orbCenter, mouse: currentMouse)
    }
  }

  override func mouseUp(with event: NSEvent) {
    defer {
      dragStartMouseScreen = nil
      dragPreviousMouseScreen = nil
      dragStartWindowOrigin = nil
      dragGestureTracker.cancel()
      didDrag = false
      mouseDownInsideOrb = false
    }
    guard mouseDownInsideOrb else { return }
    let releaseMouse = NSEvent.mouseLocation
    let metrics = dragGestureTracker.finish(at: releaseMouse, time: sampleTime(for: event))
    let orbCenter: NSPoint = {
      guard let panel = window as? NSPanel else { return releaseMouse }
      return OrbyOrbGeometry.orbCenterScreen(panel: panel)
    }()
    panelController?.endUserDrag(metrics: metrics, orbCenter: orbCenter, cursor: releaseMouse)
    if !didDrag {
      onClick?()
    }
  }

  override func resetCursorRects() {
    super.resetCursorRects()
    addCursorRect(bounds, cursor: .openHand)
  }

  private func sampleTime(for event: NSEvent) -> Date {
    Date(timeIntervalSinceReferenceDate: event.timestamp)
  }

  private func isMouseInsideOrb(for event: NSEvent) -> Bool {
    guard let panel = window as? NSPanel else { return false }
    let screen = panel.convertPoint(toScreen: event.locationInWindow)
    return OrbyOrbGeometry.isScreenPointInsideOrb(screen, panel: panel)
  }
}
