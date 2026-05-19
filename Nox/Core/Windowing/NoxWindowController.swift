import AppKit
import QuartzCore
import SwiftUI

@MainActor
final class NoxWindowController: NSObject, NSWindowDelegate {
  private var window: NSWindow?

  var isVisible: Bool {
    guard let window else { return false }
    return window.isVisible
  }

  func openOrFocus(using environment: AppEnvironment) {
    if let window {
      NSApp.activate(ignoringOtherApps: true)
      applyWindowMode(environment.preferences.windowMode, to: window)
      window.makeKeyAndOrderFront(nil)
      reveal(window)
      return
    }

    let hosting = NSHostingController(
      rootView: AnyView(
        NoxAmbientShellView()
          .environment(environment)
      )
    )

    let newWindow = makeFloatingWindow(
      contentViewController: hosting,
      mode: environment.preferences.windowMode
    )
    newWindow.delegate = self
    newWindow.center()
    newWindow.alphaValue = 0
    newWindow.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    window = newWindow
    reveal(newWindow)
  }

  func applyWindowMode(_ mode: NoxWindowMode, using environment: AppEnvironment) {
    guard let window else { return }
    applyWindowMode(mode, to: window)
  }

  func close() {
    window?.close()
  }

  func windowWillClose(_ notification: Notification) {
    window = nil
  }

  private func applyWindowMode(_ mode: NoxWindowMode, to window: NSWindow) {
    let size = mode.size
    var frame = window.frame
    frame.size = NSSize(width: size.width, height: size.height)
    window.setFrame(frame, display: true, animate: true)
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
    window.minSize = NSSize(
      width: NoxDesignTokens.Window.minWidth,
      height: NoxDesignTokens.Window.minHeight
    )
    window.maxSize = NSSize(
      width: NoxDesignTokens.Window.maxWidth,
      height: NoxDesignTokens.Window.maxHeight
    )
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
