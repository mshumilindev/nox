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

/// Native status item — persists in the primary menu bar (autosaveName) unlike overflow-prone MenuBarExtra.
@MainActor
final class NoxStatusBarController: NSObject {
    static let autosaveName = "dev.nox.Nox.statusItem"

    private var statusItem: NSStatusItem?
    private var panel: NSPanel?
    private var hostingController: NSHostingController<AnyView>?
    private var globalOutsideClickMonitor: Any?
    private var localOutsideClickMonitor: Any?
    private var ignoreOutsideCloseUntil: Date?

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
            item.behavior = []
        }
    }

    private var panelContentSize: NSSize {
        NSSize(
            width: NoxSpacing.menuBarWidth + NoxSpacing.lg * 2,
            height: 420
        )
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

        let size = panelContentSize
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .transient]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.contentViewController = hosting
        layoutPanelContent()

        self.panel = panel
    }

    private func layoutPanelContent() {
        guard let hosting = hostingController, let panel else { return }
        hosting.view.layoutSubtreeIfNeeded()
        let fitted = hosting.view.fittingSize
        let size = panelContentSize
        panel.setContentSize(
            NSSize(
                width: max(size.width, fitted.width),
                height: max(280, fitted.height)
            )
        )
    }

    /// AppKit calls status-item actions from Obj-C; hop to the main actor explicitly (Swift 6).
    @objc nonisolated private func statusItemClicked(_ sender: NSStatusBarButton) {
        Task { @MainActor [weak self] in
            self?.handleStatusItemClick(sender)
        }
    }

    private func handleStatusItemClick(_ sender: NSStatusBarButton) {
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

        layoutPanelContent()
        position(panel: panel, relativeTo: button)
        ignoreOutsideCloseUntil = Date().addingTimeInterval(0.35)

        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()

        DispatchQueue.main.async { [weak self] in
            self?.installOutsideClickMonitor()
        }
    }

    private func position(panel: NSPanel, relativeTo button: NSStatusBarButton) {
        let anchor = statusItemAnchorScreenRect(for: button)
        var frame = panel.frame
        frame.size = panelContentSize
        frame.origin.x = anchor.midX - frame.width / 2
        frame.origin.y = anchor.minY - frame.height - 6

        if let screen = screenContaining(anchor) {
            let visible = screen.visibleFrame
            frame.origin.x = min(max(frame.origin.x, visible.minX + 8), visible.maxX - frame.width - 8)
            frame.origin.y = min(max(frame.origin.y, visible.minY + 8), visible.maxY - frame.height - 8)
        }

        panel.setFrame(frame, display: true)
    }

    private func statusItemAnchorScreenRect(for button: NSStatusBarButton) -> NSRect {
        if let buttonWindow = button.window {
            let buttonFrame = button.convert(button.bounds, to: nil)
            return buttonWindow.convertToScreen(buttonFrame)
        }

        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        let menuBarHeight: CGFloat = {
            guard let screen else { return 24 }
            return max(22, screen.frame.height - screen.visibleFrame.height)
        }()
        let y = (screen?.frame.maxY ?? mouse.y) - menuBarHeight
        return NSRect(x: mouse.x - 9, y: y, width: 18, height: menuBarHeight)
    }

    private func screenContaining(_ rect: NSRect) -> NSScreen? {
        NSScreen.screens.first { $0.frame.intersects(rect) } ?? NSScreen.main
    }

    private func installOutsideClickMonitor() {
        removeOutsideClickMonitor()
        globalOutsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] _ in
            Task { @MainActor in
                self?.closeIfClickOutside()
            }
        }
        localOutsideClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] event in
            Task { @MainActor in
                self?.closeIfClickOutside(at: event.locationInWindow, from: event.window)
            }
            return event
        }
    }

    private func removeOutsideClickMonitor() {
        if let globalOutsideClickMonitor {
            NSEvent.removeMonitor(globalOutsideClickMonitor)
            self.globalOutsideClickMonitor = nil
        }
        if let localOutsideClickMonitor {
            NSEvent.removeMonitor(localOutsideClickMonitor)
            self.localOutsideClickMonitor = nil
        }
    }

    private func shouldIgnoreOutsideClose() -> Bool {
        if let ignoreOutsideCloseUntil, Date() < ignoreOutsideCloseUntil {
            return true
        }
        return false
    }

    private func closeIfClickOutside() {
        guard !shouldIgnoreOutsideClose() else { return }
        guard let panel, panel.isVisible else { return }
        closeIfClickOutside(atScreenPoint: NSEvent.mouseLocation)
    }

    private func closeIfClickOutside(at point: NSPoint, from window: NSWindow?) {
        guard !shouldIgnoreOutsideClose() else { return }
        guard let window else {
            closeIfClickOutside()
            return
        }
        let click = window.convertPoint(toScreen: point)
        closeIfClickOutside(atScreenPoint: click)
    }

    private func closeIfClickOutside(atScreenPoint click: NSPoint) {
        guard !shouldIgnoreOutsideClose() else { return }
        guard let panel, panel.isVisible else { return }
        if panel.frame.contains(click) { return }

        if let button = statusItem?.button {
            let anchor = statusItemAnchorScreenRect(for: button)
            if anchor.insetBy(dx: -6, dy: -6).contains(click) { return }
        }

        closeMenu()
    }
}
