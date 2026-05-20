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
        // Nox mesh (_nox._tcp + transport) must run at launch so peers can discover each other.
        // Apple AirPlay / BLE browsing stays gated until the Presence page opens.
        NoxAppRuntime.presenceMesh.start()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleIncomingURL(url)
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "nox", url.host == "pair" else {
            if url.pathExtension == "noxpair" || url.lastPathComponent.hasSuffix(".noxpair") {
                if let data = try? Data(contentsOf: url) {
                    Task { @MainActor in
                        try? await NoxAppRuntime.presenceMesh.importInviteData(data)
                    }
                }
            }
            return
        }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let deviceId = components?.queryItems?.first { $0.name == "deviceId" }?.value ?? ""
        let token = components?.queryItems?.first { $0.name == "invite" }?.value ?? ""
        guard !deviceId.isEmpty else { return }
        Task { @MainActor in
            await NoxAppRuntime.presenceMesh.manualConnect(
                host: "127.0.0.1",
                port: Int(NoxMeshRuntime.profile.meshPort),
                deviceId: deviceId,
                deviceName: "Invited Nox"
            )
            _ = token
        }
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
