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

struct NoxLiveSignalDeduplicatorTests {

    @Test func suppressesActiveAfterSwitch() {
        let now = Date()
        let prior = NoxLiveSignal(
            id: "1",
            timestamp: now,
            text: "Switched to Safari",
            kind: .app
        )
        let next = NoxLiveSignal(
            id: "2",
            timestamp: now.addingTimeInterval(4),
            text: "Safari active",
            kind: .app
        )
        #expect(NoxLiveSignalDeduplicator.shouldAccept(next, in: [prior]) == false)
    }
}
