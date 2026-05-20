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

@MainActor
struct NoxPresenceStabilizerTests {

    @Test func holdsBriefIdleFluctuation() {
        let stabilizer = NoxPresenceStabilizer()
        stabilizer.reset(to: .active)
        let first = stabilizer.resolve(proposed: .idle, at: Date())
        #expect(first == .active)
        let later = stabilizer.resolve(
            proposed: .idle,
            at: Date().addingTimeInterval(65)
        )
        #expect(later == .idle)
    }
}
