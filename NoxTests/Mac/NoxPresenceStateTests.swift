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

struct NoxPresenceStateTests {

    @Test @MainActor func defaultPresenceIsQuiet() {
        let environment = AppEnvironment()
        #expect(environment.presence == .quiet)
    }

    @Test func presenceTitlesExist() {
        for state in NoxPresenceState.allCases {
            #expect(!state.title.isEmpty)
            #expect(!state.symbolName.isEmpty)
        }
    }
}
