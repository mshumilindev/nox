import Foundation
import NoxMemoryCore
import Testing

struct NoxMemoryEcologyCopyTests {

    @Test func orbitEmptyIsCalmAndSpecific() {
        #expect(NoxMemoryEcologyCopy.orbitEmpty == "No nearby Orbit memory right now.")
    }

    @Test func deepSpacePeriodHintForToday() {
        #expect(NoxMemoryEcologyCopy.deepSpacePeriodHint(period: .today).contains("Older"))
    }
}
