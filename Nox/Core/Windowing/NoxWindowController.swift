import AppKit
import QuartzCore
import SwiftUI

@MainActor
final class NoxWindowController: NSObject, NSWindowDelegate {
  private var window: NSWindow?
  private var isApplyingProgrammaticFrame = false
  private var usesDefaultTopTrailingPlacement = true

  private enum WindowPlacement {
    case preserveCenter
    case topTrailing
  }

  var isVisible: Bool {
    guard let window else { return false }
    return window.isVisible
  }

  func openOrFocus(using environment: AppEnvironment) {
    if let window {
      NSApp.activate(ignoringOtherApps: true)
      applyWindowMode(environment.preferences.windowMode, to: window, animate: false)
      window.makeKeyAndOrderFront(nil)
      reveal(window)
      return
    }

    let mode = environment.preferences.windowMode
    let hosting = NSHostingController(
      rootView: AnyView(
        NoxAmbientShellView()
          .environment(environment)
      )
    )
    configureHostingController(hosting)

    let newWindow = makeFloatingWindow(
      contentViewController: hosting,
      mode: mode
    )
    newWindow.delegate = self
    newWindow.alphaValue = 0
    window = newWindow
    usesDefaultTopTrailingPlacement = true
    applyWindowMode(mode, to: newWindow, animate: false, placement: .topTrailing)
    newWindow.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    reveal(newWindow)
  }

  func applyWindowMode(
    _ mode: NoxWindowMode,
    using environment: AppEnvironment,
    animated: Bool = false
  ) {
    guard let window else { return }
    applyWindowMode(mode, to: window, animate: animated)
  }

  func close() {
    window?.close()
  }

  func windowWillClose(_ notification: Notification) {
    window = nil
    usesDefaultTopTrailingPlacement = true
  }

  func windowDidMove(_ notification: Notification) {
    guard !isApplyingProgrammaticFrame else { return }
    guard let window = notification.object as? NSWindow else { return }
    usesDefaultTopTrailingPlacement = isAtDefaultTopTrailing(window.frame)
  }

  private func applyWindowMode(
    _ mode: NoxWindowMode,
    to window: NSWindow,
    animate: Bool,
    placement: WindowPlacement = .preserveCenter
  ) {
    let size = mode.size
    let contentSize = NSSize(width: size.width, height: size.height)
    let targetFrameSize = window.frameRect(
      forContentRect: NSRect(origin: .zero, size: contentSize)
    ).size
    var frame = window.frame
    frame.size = targetFrameSize
    let effectivePlacement = resolvedPlacement(
      placement,
      for: window.frame
    )
    frame.origin = origin(
      for: frame.size,
      currentFrame: window.frame,
      placement: effectivePlacement
    )
    frame.origin = clampedOrigin(
      frame.origin,
      for: frame.size,
      visibleFrame: visibleFrame(for: window.frame)
    )
    isApplyingProgrammaticFrame = true
    window.setFrame(frame, display: true, animate: animate)
    isApplyingProgrammaticFrame = false
    usesDefaultTopTrailingPlacement = effectivePlacement == .topTrailing
    layoutWindowContent(window)
  }

  private func resolvedPlacement(
    _ placement: WindowPlacement,
    for currentFrame: NSRect
  ) -> WindowPlacement {
    switch placement {
    case .topTrailing:
      return .topTrailing
    case .preserveCenter:
      return usesDefaultTopTrailingPlacement || isAtDefaultTopTrailing(currentFrame)
        ? .topTrailing
        : .preserveCenter
    }
  }

  private func origin(
    for frameSize: NSSize,
    currentFrame: NSRect,
    placement: WindowPlacement
  ) -> NSPoint {
    switch placement {
    case .preserveCenter:
      let center = CGPoint(x: currentFrame.midX, y: currentFrame.midY)
      return NSPoint(
        x: center.x - frameSize.width / 2,
        y: center.y - frameSize.height / 2
      )
    case .topTrailing:
      let visibleFrame = visibleFrame(for: currentFrame)
      return NSPoint(
        x: visibleFrame.maxX - frameSize.width - NoxSpacing.lg,
        y: visibleFrame.maxY - frameSize.height - NoxSpacing.lg
      )
    }
  }

  private func visibleFrame(for frame: NSRect) -> NSRect {
    let center = NSPoint(x: frame.midX, y: frame.midY)
    if let screen = NSScreen.screens.first(where: { $0.frame.contains(center) }) {
      return screen.visibleFrame
    }
    if let screen = NSScreen.screens.first(where: { $0.frame.intersects(frame) }) {
      return screen.visibleFrame
    }
    return targetScreenVisibleFrame()
  }

  private func targetScreenVisibleFrame() -> NSRect {
    let mouseLocation = NSEvent.mouseLocation
    let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) }
      ?? NSScreen.main
      ?? NSScreen.screens.first
    return screen?.visibleFrame ?? .zero
  }

  private func isAtDefaultTopTrailing(_ frame: NSRect) -> Bool {
    let visibleFrame = visibleFrame(for: frame)
    let expected = NSPoint(
      x: visibleFrame.maxX - frame.width - NoxSpacing.lg,
      y: visibleFrame.maxY - frame.height - NoxSpacing.lg
    )
    let tolerance: CGFloat = 8
    return abs(frame.minX - expected.x) <= tolerance
      && abs(frame.minY - expected.y) <= tolerance
  }

  private func clampedOrigin(
    _ origin: NSPoint,
    for frameSize: NSSize,
    visibleFrame: NSRect
  ) -> NSPoint {
    NSPoint(
      x: min(max(origin.x, visibleFrame.minX), visibleFrame.maxX - frameSize.width),
      y: min(max(origin.y, visibleFrame.minY), visibleFrame.maxY - frameSize.height)
    )
  }

  private func configureHostingController(_ hosting: NSHostingController<AnyView>) {
    hosting.view.translatesAutoresizingMaskIntoConstraints = true
    hosting.view.autoresizingMask = [.width, .height]
  }

  private func layoutWindowContent(_ window: NSWindow) {
    window.contentView?.layoutSubtreeIfNeeded()
    window.contentViewController?.view.layoutSubtreeIfNeeded()
    window.displayIfNeeded()
  }

  private func makeFloatingWindow(
    contentViewController: NSViewController,
    mode: NoxWindowMode
  ) -> NSWindow {
    let rect = NSRect(
      x: 0,
      y: 0,
      width: mode.size.width,
      height: mode.size.height
    )

    let window = NoxFloatingWindow(
      contentRect: rect,
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false
    )

    window.contentViewController = contentViewController
    window.contentView?.autoresizingMask = [.width, .height]
    window.title = "Nox"
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.titlebarSeparatorStyle = .none
    window.isMovableByWindowBackground = false
    window.isMovable = true
    window.toolbar = nil
    window.backgroundColor = NSColor(NoxDesignTokens.ColorRole.canvas)
    window.isOpaque = true
    window.hasShadow = true
    window.level = .floating
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    let minContentSize = NSSize(
      width: NoxDesignTokens.Window.minWidth,
      height: NoxDesignTokens.Window.minHeight
    )
    let maxContentSize = NSSize(
      width: NoxDesignTokens.Window.maxWidth,
      height: NoxDesignTokens.Window.maxHeight
    )
    window.contentMinSize = minContentSize
    window.contentMaxSize = maxContentSize
    window.minSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: minContentSize)).size
    window.maxSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: maxContentSize)).size
    window.isReleasedWhenClosed = false

    return window
  }

  private func reveal(_ window: NSWindow) {
    NSAnimationContext.runAnimationGroup { context in
      context.duration = NoxDesignTokens.Animation.panelReveal
      context.timingFunction = CAMediaTimingFunction(name: .easeOut)
      window.animator().alphaValue = 1
    }
  }
}
