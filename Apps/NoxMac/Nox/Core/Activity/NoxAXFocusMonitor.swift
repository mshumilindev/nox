import Foundation
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
import ApplicationServices

/// Fires when the focused window or its title changes (Accessibility).
nonisolated final class NoxAXFocusMonitor: @unchecked Sendable {
    private let queue = DispatchQueue(label: "dev.nox.ax-focus-monitor", qos: .userInitiated)
    private var observer: AXObserver?
    private var observedPID: pid_t = -1
    private var observedWindow: AXUIElement?
    private var onFocusChange: (@Sendable () -> Void)?
    private var isEnabled = false

    func setEnabled(_ enabled: Bool, onFocusChange: @escaping @Sendable () -> Void) {
        queue.async { [weak self] in
            guard let self else { return }
            self.onFocusChange = onFocusChange
            self.isEnabled = enabled
            if !enabled {
                self.teardown()
            }
        }
    }

    func frontmostApplicationChanged(pid: pid_t, accessibilityGranted: Bool) {
        queue.async { [weak self] in
            guard let self, self.isEnabled, accessibilityGranted else { return }
            self.rebind(applicationPID: pid)
        }
    }

    func stop() {
        queue.async { [weak self] in
            self?.teardown()
            self?.onFocusChange = nil
            self?.isEnabled = false
        }
    }

    private func rebind(applicationPID: pid_t) {
        guard applicationPID > 0 else { return }
        if observedPID == applicationPID, observer != nil { return }

        teardown()
        observedPID = applicationPID

        var axObserver: AXObserver?
        let callback: AXObserverCallback = { _, _, _, refcon in
            guard let refcon else { return }
            let monitor = Unmanaged<NoxAXFocusMonitor>.fromOpaque(refcon).takeUnretainedValue()
            monitor.handleAXNotification()
        }

        let error = AXObserverCreate(applicationPID, callback, &axObserver)
        guard error == .success, let axObserver else { return }

        let appElement = AXUIElementCreateApplication(applicationPID)
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        _ = AXObserverAddNotification(
            axObserver,
            appElement,
            kAXFocusedWindowChangedNotification as CFString,
            selfPtr
        )

        let source = AXObserverGetRunLoopSource(axObserver)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)

        observer = axObserver
        observeFocusedWindow(in: appElement)
    }

    private func observeFocusedWindow(in appElement: AXUIElement) {
        var focusedWindow: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        ) == .success,
            let windowRef = focusedWindow else {
            return
        }

        let windowElement = windowRef as! AXUIElement
        observedWindow = windowElement

        guard let observer else { return }
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        _ = AXObserverAddNotification(
            observer,
            windowElement,
            kAXTitleChangedNotification as CFString,
            selfPtr
        )
    }

    private func handleAXNotification() {
        guard isEnabled else { return }
        if observedPID > 0 {
            let appElement = AXUIElementCreateApplication(observedPID)
            observeFocusedWindow(in: appElement)
        }
        onFocusChange?()
    }

    private func teardown() {
        if let observer {
            let source = AXObserverGetRunLoopSource(observer)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
        }
        observer = nil
        observedWindow = nil
        observedPID = -1
    }
}
