import Foundation
import SwiftUI
import Testing
@testable import Nox

@Suite("Orby orb lighting")
struct OrbyOrbLightingTests {
  private func context(sleepDepth: CGFloat, luminance: Double = 0.78) -> OrbyOrbLightingContext {
    OrbyOrbLightingContext(sleepDepth: sleepDepth, backgroundLuminance: luminance)
  }

  @Test("Lit hemisphere is half the rim")
  func highlightArcIsHalf() {
    #expect(OrbyOrbLighting.highlightArcFraction == 0.5)
  }

  @Test("Body fill builds across sleep cycle")
  func bodyFillBuildsAcrossSleep() {
    let tint = OrbyTintAppearance()
    for depth: CGFloat in [0, 0.25, 0.5, 0.75, 1] {
      _ = OrbyOrbLighting.bodyFill(tint: tint, context: context(sleepDepth: depth))
    }
  }
}
