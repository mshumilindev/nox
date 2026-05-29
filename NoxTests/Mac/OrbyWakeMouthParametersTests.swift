import XCTest
@testable import Nox

final class OrbyWakeMouthParametersTests: XCTestCase {
  func testYawnEndsClosed() {
    let end = OrbyWakeMouthParameters.yawn(progress: 1)
    XCTAssertTrue(OrbyWakeMouthParameters.matchesClosedSlit(end))
    XCTAssertLessThan(end.openness, 0.05)
  }

  func testYawnStartsClosed() {
    let start = OrbyWakeMouthParameters.yawn(progress: 0)
    XCTAssertTrue(OrbyWakeMouthParameters.matchesClosedSlit(start))
  }

  func testYawnPeakIsVerticalAndClamped() {
    let mid = OrbyWakeMouthParameters.yawn(progress: 0.55)
    XCTAssertGreaterThan(mid.openness, 0.9)
    XCTAssertGreaterThan(mid.ovalHeight, mid.ovalWidth)
    XCTAssertLessThanOrEqual(mid.ovalHeight, 22)
    XCTAssertLessThanOrEqual(mid.ovalWidth, 18)
    XCTAssertLessThanOrEqual(mid.verticalOffset, 1)
  }

  func testYawnHoldPlateau() {
    let a = OrbyWakeMouthParameters.yawn(progress: 0.56)
    let b = OrbyWakeMouthParameters.yawn(progress: 0.70)
    XCTAssertEqual(a.openness, 1, accuracy: 0.01)
    XCTAssertEqual(b.openness, 1, accuracy: 0.01)
  }
}
