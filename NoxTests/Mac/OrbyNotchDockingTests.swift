import CoreGraphics
import XCTest
import NoxShrineCore
@testable import Nox

@MainActor
final class OrbyNotchDockingTests: XCTestCase {
  func testProximityIncreasesNearAnchor() {
    let layout = sampleLayout
    let far = CGPoint(x: layout.notchAnchor.x - 90, y: layout.notchAnchor.y - 50)
    let near = CGPoint(x: layout.notchAnchor.x - 8, y: layout.notchAnchor.y - 4)
    XCTAssertTrue(OrbyNotchGeometry.isInCaptureZone(orbCenter: far, layout: layout))
    XCTAssertTrue(OrbyNotchGeometry.isInCaptureZone(orbCenter: near, layout: layout))
    let farP = OrbyNotchGeometry.proximity(from: far, layout: layout)
    let nearP = OrbyNotchGeometry.proximity(from: near, layout: layout)
    XCTAssertGreaterThan(nearP, farP)
  }

  func testDropZoneContainsAnchor() {
    let layout = sampleLayout
    XCTAssertTrue(OrbyNotchGeometry.isInDropZone(point: layout.notchAnchor, layout: layout))
  }

  func testCursorCorridorRequiresTopBand() {
    let screen = NSScreen.main ?? NSScreen.screens[0]
    let frame = screen.frame
    let lowCursor = NSPoint(x: frame.midX, y: frame.minY + 40)
    XCTAssertFalse(OrbyNotchGeometry.isCursorInNotchCaptureCorridor(cursor: lowCursor, on: screen))
  }

  func testNotchResistanceAppearanceEscalatesWithTension() {
    let base = OrbyEmotionAppearance.neutralDefault
    let low = OrbyNotchResistanceAppearance.apply(tension: 0.1, to: base)
    let mid = OrbyNotchResistanceAppearance.apply(tension: 0.55, to: base)
    let high = OrbyNotchResistanceAppearance.apply(tension: 0.9, to: base)
    XCTAssertEqual(low.tint.redShift, 0, accuracy: 0.001)
    XCTAssertGreaterThan(mid.tint.redShift, low.tint.redShift)
    XCTAssertGreaterThan(high.tint.redShift, mid.tint.redShift)
    XCTAssertLessThan(high.leftEye.height, base.leftEye.height)
    XCTAssertLessThan(high.mouth.cornerLift, 0)
  }

  func testPullTensionAtThresholdIsOne() {
    let tension = OrbyNotchGeometry.pullTension(
      pullDistance: OrbyNotchDockingMetrics.undockDetachThreshold
    )
    XCTAssertEqual(tension, 1, accuracy: 0.001)
  }

  func testClampToVisibleFrameIsNearestPointOnAxis() {
    let visible = NoxShrineScreenRect(x: 0, y: 100, width: 800, height: 600)
    let size = NoxShrineSize(width: 104, height: 104)
    let clamped = NoxShrineMiniBubblePlacement.clamp(
      origin: NoxShrinePoint(x: 400, y: 820),
      panelSize: size,
      visibleFrame: visible
    )
    XCTAssertEqual(clamped.y, 596)
    XCTAssertEqual(clamped.x, 400)
  }

  private var sampleLayout: OrbyNotchLayout {
    let fake = CGRect(x: 700, y: 1100, width: 128, height: 32)
    return OrbyNotchLayout(
      screenFrame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
      fakeNotchFrame: fake,
      captureZone: fake.insetBy(dx: -120, dy: -80),
      dropZone: fake.insetBy(dx: -18, dy: -18),
      notchAnchor: CGPoint(x: fake.midX, y: fake.midY),
      orbyXOffsetFromCapsuleCenter: 0
    )
  }
}
