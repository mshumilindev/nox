import Foundation
import Testing
@testable import Nox

@Suite("Orby phase mouth presets")
struct OrbyPhaseMouthPresetsTests {
  @Test("Hover excited uses surprised round mouth")
  func hoverExcitedSurprisedMouth() {
    let mouth = OrbyPhaseMouthPresets.hoverExcited
    #expect(mouth.openness >= 0.95)
    #expect(mouth.ovalWidth >= 8)
    #expect(mouth.ovalHeight >= mouth.ovalWidth * 0.9)
    #expect(mouth.cornerLift == 0)
  }
}
