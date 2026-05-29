import Foundation
import Testing
@testable import Nox

@Suite("Orby idle microbehavior policy")
struct OrbyIdleMicrobehaviorPolicyTests {
  private func context(
    phase: OrbyMiniVisualPhase = .awake,
    isHovering: Bool = false,
    cursorInsideOrb: Bool = false,
    secondsUntilSleepThreshold: TimeInterval = 20
  ) -> OrbyIdleMicroContext {
    OrbyIdleMicroContext(
      mood: .neutral,
      phase: phase,
      isVisible: true,
      isHovering: isHovering,
      isDragging: false,
      isContextMenuOpen: false,
      cursorInsideOrb: cursorInsideOrb,
      secondsUntilSleepThreshold: secondsUntilSleepThreshold
    )
  }

  @Test("Hover suspends scheduling")
  func hoverSuspendsScheduling() {
    #expect(OrbyIdleMicrobehaviorPolicy.schedulingSuspended(for: .hoverExcited, isContextMenuOpen: false))
  }

  @Test("Stylized beats blocked under hover")
  func stylizedBlockedOnHover() {
    let ctx = context(isHovering: true, cursorInsideOrb: true)
    #expect(!OrbyIdleMicrobehaviorPolicy.canRun(.cosmicCometWatch, context: ctx))
    #expect(OrbyIdleMicrobehaviorPolicy.canRun(.microSmile, context: ctx))
  }

  @Test("Near sleep only subtle microbehaviors")
  func nearSleepGate() {
    let ctx = context(secondsUntilSleepThreshold: 6)
    #expect(OrbyIdleMicrobehaviorPolicy.canRun(.microSmile, context: ctx))
    #expect(!OrbyIdleMicrobehaviorPolicy.canRun(.bubbleBlow, context: ctx))
  }
}
