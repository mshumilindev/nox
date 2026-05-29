import CoreGraphics
import XCTest
@testable import Nox

final class OrbyDragPhysicsTests: XCTestCase {
  private let constants = OrbyDragPhysicsConstants()

  func testSpeedBelowSoftStartYieldsZeroIntensity() {
    let raw = OrbyDragPhysicsMath.dragIntensity(
      smoothedSpeed: 100,
      softStart: constants.deformationSoftStartSpeed,
      maxVisual: constants.deformationMaxVisualSpeed
    )
    XCTAssertEqual(raw, 0, accuracy: 0.001)
    XCTAssertEqual(OrbyDragPhysicsMath.easeOutCubic(raw), 0, accuracy: 0.001)
  }

  func testSpeedAtMaxVisualYieldsIntensityNearOne() {
    let raw = OrbyDragPhysicsMath.dragIntensity(
      smoothedSpeed: constants.deformationMaxVisualSpeed,
      softStart: constants.deformationSoftStartSpeed,
      maxVisual: constants.deformationMaxVisualSpeed
    )
    XCTAssertEqual(raw, 1, accuracy: 0.001)
    XCTAssertEqual(OrbyDragPhysicsMath.easeOutCubic(raw), 1, accuracy: 0.001)
  }

  func testStretchCompressionClamped() {
    let targets = OrbyDragPhysicsMath.deformationTargets(
      deformationIntensity: 1,
      accelerationMagnitude: 20_000,
      constants: constants
    )
    XCTAssertLessThanOrEqual(targets.stretch, constants.absoluteStretchCap)
    XCTAssertGreaterThanOrEqual(targets.compression, constants.absoluteCompressionFloor)
  }

  func testHorizontalVelocityGivesHorizontalAngle() {
    let angle = OrbyDragPhysicsMath.directionAngle(
      for: CGVector(dx: 500, dy: 0),
      deadZone: constants.velocityDeadZone
    )
    XCTAssertNotNil(angle)
    XCTAssertEqual(angle!, 0, accuracy: 0.001)
  }

  func testVerticalScreenDragGivesVerticalViewAngle() {
    let velocity = OrbyDragPhysicsMath.screenDeltaToViewVelocity(
      delta: CGSize(width: 0, height: 100),
      dt: 0.1
    )
    let angle = OrbyDragPhysicsMath.directionAngle(
      for: velocity,
      deadZone: constants.velocityDeadZone
    )
    XCTAssertNotNil(angle)
    XCTAssertEqual(angle!, -.pi / 2, accuracy: 0.05)
  }

  func testAccelerationBoostRespectsCap() {
    let low = OrbyDragPhysicsMath.deformationTargets(
      deformationIntensity: 1,
      accelerationMagnitude: 0,
      constants: constants
    )
    let high = OrbyDragPhysicsMath.deformationTargets(
      deformationIntensity: 1,
      accelerationMagnitude: 50_000,
      constants: constants
    )
    XCTAssertLessThanOrEqual(high.stretch, constants.absoluteStretchCap)
    XCTAssertGreaterThanOrEqual(high.compression, constants.absoluteCompressionFloor)
    XCTAssertGreaterThan(high.stretch, low.stretch)
    XCTAssertLessThan(high.compression, low.compression)
  }

  func testFaceLagTargetClampsToMax() {
    let target = OrbyDragPhysicsMath.faceLagTarget(
      dragDirection: CGVector(dx: 800, dy: 0),
      deformationIntensity: 1,
      maxLag: constants.maxFaceLag
    )
    XCTAssertEqual(target.width, -constants.maxFaceLag, accuracy: 0.001)
    XCTAssertEqual(target.height, 0, accuracy: 0.001)
  }

  @MainActor
  func testSlowDragStaysNearRestDeformation() async {
    let sim = OrbyDragPhysicsSimulator()
    let t0 = Date(timeIntervalSinceReferenceDate: 20_000)
    sim.begin(sampleTime: t0)
    for step in 1...20 {
      sim.ingest(screenDelta: CGSize(width: 4, height: 0), sampleTime: t0.addingTimeInterval(Double(step) * 0.05))
    }
    let snap = sim.snapshot()
    XCTAssertLessThan(snap.stretch, 1.02)
    XCTAssertGreaterThan(snap.compression, 0.99)
  }
}
