import Foundation
import Testing
@testable import Nox

@Suite("Orby cheek blush layout")
struct OrbyCheekBlushGeometryTests {
  @Test("Blush sits below excited eye bottoms with required gap")
  func belowExcitedEyes() {
    let left = OrbyEyeAppearance(width: 10.5, height: 11, verticalShift: -0.5)
    let right = left
    let layout = OrbyCheekBlushGeometry.layout(leftEye: left, rightEye: right, eyeSpacing: 16)
    #expect(OrbyCheekBlushGeometry.markTopIsBelowEyes(layout: layout, leftEye: left, rightEye: right))
    #expect(layout.markSize.width == OrbyCheekBlushGeometry.markWidth)
    #expect(layout.markSize.height == OrbyCheekBlushGeometry.markHeight)
  }

  @Test("Policy suppresses blush during drag")
  func suppressedWhenDragging() {
    #expect(OrbyCheekBlushPolicy.isSuppressed(phase: .dragging))
    #expect(OrbyCheekBlushPolicy.resolvedStrength(phase: .dragging, compositorStrength: 1, idleMicro: nil) == 0)
  }

  @Test("Policy allows hover excited blush")
  func hoverExcitedBlush() {
    #expect(!OrbyCheekBlushPolicy.isSuppressed(phase: .hoverExcited))
    #expect(
      OrbyCheekBlushPolicy.resolvedStrength(phase: .hoverExcited, compositorStrength: 1, idleMicro: nil) == 1
    )
  }
}
