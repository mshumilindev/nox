import AppKit
import QuartzCore
import SwiftUI

@MainActor
final class NoxWindowController: NSObject, NSWindowDelegate {
  private var window: NSWindow?

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
    frame.origin = origin(
      for: frame.size,
      currentFrame: window.frame,
      placement: placement
    )
    window.setFrame(frame, display: true, animate: animate)
    layoutWindowContent(window)
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
      let visibleFrame = targetScreenVisibleFrame()
      return NSPoint(
        x: visibleFrame.maxX - frameSize.width - NoxSpacing.lg,
        y: visibleFrame.maxY - frameSize.height - NoxSpacing.lg
      )
    }
  }

  private func targetScreenVisibleFrame() -> NSRect {
    let mouseLocation = NSEvent.mouseLocation
    let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) }
      ?? NSScreen.main
      ?? NSScreen.screens.first
    return screen?.visibleFrame ?? .zero
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
