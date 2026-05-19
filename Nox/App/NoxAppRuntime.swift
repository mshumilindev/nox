import Foundation

@MainActor
enum NoxAppRuntime {
    static let environment = AppEnvironment()
    static let panelState = NoxPanelState()
    static let statusBar = NoxStatusBarController()
}
