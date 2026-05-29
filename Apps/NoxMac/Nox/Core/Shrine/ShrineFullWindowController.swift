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
final class ShrineFullWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    var isVisible: Bool { window?.isVisible == true }

    func openOrFocus(using environment: AppEnvironment, surfaceController: ShrineSurfaceController) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(
            rootView: AnyView(
                ShrineFullSurfacePlaceholderView(surfaceController: surfaceController)
                    .environment(environment)
            )
        )

        let size = NSSize(width: 320, height: 380)
        let rect = NSRect(origin: .zero, size: size)
        let window = NSPanel(
            contentRect: rect,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Nox Shrine"
        window.contentViewController = hosting
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.center()
        window.delegate = self
        self.window = window
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
