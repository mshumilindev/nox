import SwiftUI

@main
struct NoxApp: App {
    @NSApplicationDelegateAdaptor(NoxAppDelegate.self) private var appDelegate

    var body: some Scene {
        // Menu bar UI is owned by NoxStatusBarController (NSStatusItem), not MenuBarExtra.
        Settings {
            EmptyView()
        }
    }
}
