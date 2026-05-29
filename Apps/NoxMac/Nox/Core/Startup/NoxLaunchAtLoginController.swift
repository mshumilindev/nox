import Foundation
import AppKit
import Combine
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
import ServiceManagement

/// Registers the installed main app as a modern macOS login item.
@MainActor
final class NoxLaunchAtLoginController: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var requiresApproval = false
    @Published private(set) var statusMessage = ""
    @Published private(set) var errorMessage: String?

    private let service = SMAppService.mainApp

    init() {
        refresh()
    }

    func setEnabled(_ enabled: Bool) {
        errorMessage = nil

        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        refresh()
    }

    func refresh() {
        switch service.status {
        case .enabled:
            isEnabled = true
            requiresApproval = false
            statusMessage = "Nox will open in the menu bar when you log in."
        case .requiresApproval:
            isEnabled = true
            requiresApproval = true
            statusMessage = "Allow Nox in System Settings > General > Login Items to finish enabling launch at login."
        case .notRegistered:
            isEnabled = false
            requiresApproval = false
            statusMessage = "Nox will stay closed until you open it."
        case .notFound:
            isEnabled = false
            requiresApproval = false
            statusMessage = "Install and launch Nox from /Applications before enabling launch at login."
        @unknown default:
            isEnabled = false
            requiresApproval = false
            statusMessage = "Launch-at-login status is unavailable."
        }
    }

    func openLoginItemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
