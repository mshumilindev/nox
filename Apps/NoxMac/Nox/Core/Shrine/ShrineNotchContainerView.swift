import AppKit

/// AppKit container for Notch Orby: capsule hit target + undock drag.
@MainActor
final class ShrineNotchContainerView: NSView {
  private let hostingView: NSView
  private weak var dockingController: OrbyNotchDockingController?

  private var dragStartMouseScreen: NSPoint?
  private var didDrag = false
  private var mouseDownInside = false

  var onClick: (() -> Void)?

  init(hostingView: NSView, dockingController: OrbyNotchDockingController) {
    self.hostingView = hostingView
    self.dockingController = dockingController
    super.init(frame: .zero)
    wantsLayer = true
    layer?.backgroundColor = .clear
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
    mouseDownInside = isMouseInsideInteractiveRegion(for: event)
    guard mouseDownInside else { return }
    let mouse = NSEvent.mouseLocation
    dragStartMouseScreen = mouse
    didDrag = false
    dockingController?.beginNotchUndockDrag(at: mouse)
  }

  override func rightMouseDown(with event: NSEvent) {
    guard isMouseInsideInteractiveRegion(for: event) else { return }
    dockingController?.noteContextMenuOpened()
    hostingView.rightMouseDown(with: event)
  }

  override func mouseDragged(with event: NSEvent) {
    guard mouseDownInside, let start = dragStartMouseScreen else { return }
    let currentMouse = NSEvent.mouseLocation
    let dx = currentMouse.x - start.x
    let dy = currentMouse.y - start.y
    if abs(dx) > 1.5 || abs(dy) > 1.5 { didDrag = true }
  }

  override func mouseUp(with event: NSEvent) {
    defer {
      dragStartMouseScreen = nil
      didDrag = false
      mouseDownInside = false
    }
    guard mouseDownInside else { return }
    if !didDrag {
      onClick?()
    }
  }

  override func resetCursorRects() {
    super.resetCursorRects()
    addCursorRect(interactiveRect, cursor: .openHand)
  }

  private var interactiveRect: NSRect {
    // Hit target covers the Orby area (left portion of the extended capsule).
    let orbyW = OrbyNotchDockingMetrics.fakeNotchWidth
    let orbyH = OrbyNotchDockingMetrics.fakeNotchHeight
    let xOffset = dockingController?.orbyXOffsetInCapsule ?? 0
    return NSRect(
      x: (bounds.width / 2) + xOffset - orbyW / 2,
      y: (bounds.height - orbyH) / 2,
      width: orbyW,
      height: orbyH
    )
  }

  private func isMouseInsideInteractiveRegion(for event: NSEvent) -> Bool {
    let local = convert(event.locationInWindow, from: nil)
    return interactiveRect.contains(local)
  }
}
