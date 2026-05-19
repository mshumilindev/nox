import AppKit

/// Agent app (`LSUIElement`): menu-bar-only, no Dock icon.
final class NoxAppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NoxAppRuntime.statusBar.install(
            environment: NoxAppRuntime.environment,
            panelState: NoxAppRuntime.panelState
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        let semaphore = DispatchSemaphore(value: 0)
        Task { @MainActor in
            await NoxLifecycleCoordinator.contextService?.checkpointBeforeTerminate()
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 2)
    }
}
