import SwiftUI
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

@main
struct NoxApp: App {
    @NSApplicationDelegateAdaptor(NoxAppDelegate.self) private var appDelegate

    var body: some Scene {
        // Menu bar UI is owned by NoxStatusBarController (NSStatusItem), not MenuBarExtra.
        Settings {
            NoxSettingsView()
        }
    }
}
