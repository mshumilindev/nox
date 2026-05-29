import XCTest
@testable import Nox

final class OrbyWakeYawnMotionTests: XCTestCase {
  func testHeadArcMovesLeftThenTopThenRight() {
    let left = OrbyWakeYawnMotion.headTurn(progress: 0.12)
    let top = OrbyWakeYawnMotion.headTurn(progress: 0.50)
    let right = OrbyWakeYawnMotion.headTurn(progress: 0.80)
    XCTAssertLessThan(left.y, 0)
    XCTAssertLessThan(top.x, 0)
    XCTAssertGreaterThan(right.y, 0)
  }

  func testHeadEndsNearCenter() {
    let end = OrbyWakeYawnMotion.headTurn(progress: 1)
    XCTAssertLessThan(abs(end.x), 0.2)
    XCTAssertLessThan(abs(end.y), 0.2)
  }

  func testEyesStaySleepyDuringYawnHold() {
    let mid = OrbyWakeYawnMotion.eyelidClosure(progress: 0.62)
    XCTAssertEqual(mid, 0.93, accuracy: 0.001)
  }

  func testEyesEaseOpenAfterYawnClose() {
    let end = OrbyWakeYawnMotion.eyelidClosure(progress: 1)
    XCTAssertEqual(end, 0.81, accuracy: 0.001)
  }

  func testEyesStartNearlyClosed() {
    let start = OrbyWakeYawnMotion.eyelidClosure(progress: 0.05)
    XCTAssertEqual(start, 0.96, accuracy: 0.001)
  }
}
