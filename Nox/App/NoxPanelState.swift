import Foundation
import Observation

@Observable
@MainActor
final class NoxPanelState {
    private let windowController = NoxWindowController()

    var isDashboardOpen: Bool {
        windowController.isVisible
    }

    func openDashboard(using environment: AppEnvironment) async {
        await environment.prepareForDashboard()
        windowController.openOrFocus(using: environment)
    }

    func closeDashboard() {
        windowController.close()
    }

    func applyWindowMode(
        _ mode: NoxWindowMode,
        using environment: AppEnvironment,
        animated: Bool = false
    ) {
        windowController.applyWindowMode(mode, using: environment, animated: animated)
    }
}
