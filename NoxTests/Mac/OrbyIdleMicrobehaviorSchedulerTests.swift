import XCTest
@testable import Nox

@MainActor
final class OrbyIdleMicrobehaviorSchedulerTests: XCTestCase {
  func testPausePreservesNextEligibleDeadline() async {
    let scheduler = OrbyIdleMicrobehaviorScheduler()
    let t0 = Date(timeIntervalSinceReferenceDate: 50_000)
    scheduler.noteShow()
    guard let deadline = scheduler.nextEligibleAtForTesting else {
      XCTFail("Expected initial schedule deadline")
      return
    }

    scheduler.setSchedulingSuspended(true)
    try? await Task.sleep(nanoseconds: 50_000_000)

    XCTAssertEqual(scheduler.nextEligibleAtForTesting, deadline)
    XCTAssertTrue(scheduler.isSchedulingSuspended)

    scheduler.setSchedulingSuspended(false)
    XCTAssertEqual(scheduler.nextEligibleAtForTesting, deadline)
    XCTAssertFalse(scheduler.isSchedulingSuspended)
    _ = t0
  }

  func testPickRandomUsesMultipleKindsOverManyRolls() {
    var kinds = Set<OrbyIdleMicrobehavior>()
    let context = OrbyIdleMicroContext(
      mood: .neutral,
      phase: .awake,
      isVisible: true,
      isHovering: false,
      isDragging: false,
      isContextMenuOpen: false,
      cursorInsideOrb: false,
      secondsUntilSleepThreshold: 20
    )
    for _ in 0..<160 {
      if let pick = OrbyIdleMicrobehaviorWeights.pickRandom(context: context) {
        kinds.insert(pick)
      }
    }
    XCTAssertGreaterThanOrEqual(kinds.count, 4)
    XCTAssertEqual(OrbyIdleMicrobehavior.allCases.count, 20)
    XCTAssertEqual(OrbyIdleMicrobehavior.allCases.filter(\.isStylized).count, 5)
  }

  func testHoverDoesNotScheduleMicrobehavior() {
    let context = OrbyIdleMicroContext(
      mood: .neutral,
      phase: .hoverExcited,
      isVisible: true,
      isHovering: true,
      isDragging: false,
      isContextMenuOpen: false,
      cursorInsideOrb: true,
      secondsUntilSleepThreshold: 20
    )
    XCTAssertNil(OrbyIdleMicrobehaviorWeights.pickRandom(context: context))
  }
}
