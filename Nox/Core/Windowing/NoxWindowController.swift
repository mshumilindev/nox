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
            window.makeKeyAndOrderFront(nil)
            reveal(window)
            return
        }

        let hosting = NSHostingController(
            rootView: AnyView(
                NoxDashboardView()
                    .environment(environment)
            )
        )

        let newWindow = makeFloatingWindow(contentViewController: hosting)
        newWindow.delegate = self
        newWindow.center()
        newWindow.alphaValue = 0
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = newWindow
        reveal(newWindow)
    }

    func close() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }

    private func makeFloatingWindow(contentViewController: NSViewController) -> NSWindow {
        let rect = NSRect(
            x: 0,
            y: 0,
            width: NoxDesignTokens.Window.width,
            height: NoxDesignTokens.Window.height
        )

        let window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.contentViewController = contentViewController
        window.title = "Nox"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
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
