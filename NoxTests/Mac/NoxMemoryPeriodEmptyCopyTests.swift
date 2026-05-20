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

struct NoxMemoryPeriodEmptyCopyTests {

    @Test func yesterdayEmptyCopyIsHistorical() {
        let title = NoxMemoryPeriodEmptyCopy.title(
            period: .yesterday,
            stats: .empty
        )
        let detail = NoxMemoryPeriodEmptyCopy.detail(period: .yesterday)
        #expect(!title.localizedCaseInsensitiveContains("forming"))
        #expect(detail.localizedCaseInsensitiveContains("Historical"))
    }
}
