import Foundation
import Observation

@Observable
@MainActor
final class NoxPanelState {
    private let windowController = NoxWindowController()

    var isDashboardOpen: Bool {
        windowController.isVisible
    }

    func openDashboard(using environment: AppEnvironment) {
        windowController.openOrFocus(using: environment)
    }

    func closeDashboard() {
        windowController.close()
    }

    func applyWindowMode(_ mode: NoxWindowMode, using environment: AppEnvironment) {
        windowController.applyWindowMode(mode, using: environment)
    }
}
