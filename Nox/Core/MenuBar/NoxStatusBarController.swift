import AppKit
import SwiftUI

/// Native status item — persists in the primary menu bar (autosaveName) unlike overflow-prone MenuBarExtra.
@MainActor
final class NoxStatusBarController: NSObject {
    static let autosaveName = "dev.nox.Nox.statusItem"

    private var statusItem: NSStatusItem?
    private var panel: NSPanel?
    private var hostingController: NSHostingController<AnyView>?
    private var outsideClickMonitor: Any?

    private weak var environment: AppEnvironment?
    private weak var panelState: NoxPanelState?

    func install(environment: AppEnvironment, panelState: NoxPanelState) {
        self.environment = environment
        self.panelState = panelState

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.autosaveName = Self.autosaveName
        item.isVisible = true
        configureRemovalBehavior(item)

        guard let button = item.button else { return }
        button.image = NoxMenuBarIcon.makeTemplateImage()
        button.imagePosition = .imageOnly
        button.toolTip = "Nox"
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        statusItem = item
        buildPanelIfNeeded()
        environment.startIfNeeded()
    }

    func closeMenu() {
        panel?.orderOut(nil)
        removeOutsideClickMonitor()
    }

    // MARK: - Private

    private func configureRemovalBehavior(_ item: NSStatusItem) {
        if #available(macOS 14.0, *) {
            // Default: not in overflow "removable" set; user keeps Nox in the menu bar.
            item.behavior = []
        }
    }

    private func buildPanelIfNeeded() {
        guard panel == nil,
              let environment,
              let panelState else { return }

        let root = NoxMenuBarView()
            .environment(environment)
            .environment(panelState)
            .environment(\.noxMenuBarDismiss) { [weak self] in
                self?.closeMenu()
            }

        let hosting = NSHostingController(rootView: AnyView(root))
        hostingController = hosting

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 420),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.contentViewController = hosting
        panel.setContentSize(hosting.view.fittingSize)

        self.panel = panel
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            return
        }
        toggleMenu(relativeTo: sender)
    }

    private func toggleMenu(relativeTo button: NSStatusBarButton) {
        buildPanelIfNeeded()
        guard let panel else { return }

        if panel.isVisible {
            closeMenu()
            return
        }

        position(panel: panel, relativeTo: button)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        installOutsideClickMonitor()
    }

    private func position(panel: NSPanel, relativeTo button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }
        let buttonFrame = button.convert(button.bounds, to: nil)
        let screenFrame = buttonWindow.convertToScreen(buttonFrame)
        var frame = panel.frame
        frame.origin.x = screenFrame.midX - frame.width / 2
        frame.origin.y = screenFrame.minY - frame.height - 6
        panel.setFrame(frame, display: true)
    }

    private func installOutsideClickMonitor() {
        removeOutsideClickMonitor()
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] _ in
            Task { @MainActor in
                self?.closeIfClickOutside()
            }
        }
    }

    private func removeOutsideClickMonitor() {
        if let outsideClickMonitor {
            NSEvent.removeMonitor(outsideClickMonitor)
            self.outsideClickMonitor = nil
        }
    }

    private func closeIfClickOutside() {
        guard let panel, panel.isVisible else { return }
        let click = NSEvent.mouseLocation
        if panel.frame.contains(click) { return }
        if let button = statusItem?.button, let window = button.window {
            let buttonFrame = button.convert(button.bounds, to: nil)
            let screenFrame = window.convertToScreen(buttonFrame)
            if screenFrame.contains(click) { return }
        }
        closeMenu()
    }
}
