import Foundation
import Testing
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
@testable import Nox

struct NoxPanelStateTests {

    @Test @MainActor func dashboardStartsClosed() {
        let panelState = NoxPanelState()
        #expect(panelState.isDashboardOpen == false)
    }
}
