import CoreGraphics
import XCTest
@testable import Nox

final class OrbyDragGestureClassifierTests: XCTestCase {
  private let thresholds = OrbyDragDazedThresholds()

  // MARK: - Required cases

  func testLongSlowDragDoesNotDaze() {
    let metrics = metricsFrom(relativePoints: [
      (0, 0, 0),
      (1.0, 200, 0),
      (2.0, 400, 0),
      (3.0, 600, 0)
    ])
    XCTAssertEqual(classify(metrics), .normal)
    XCTAssertLessThan(metrics.averageSpeed, 300)
    XCTAssertLessThan(metrics.releaseSpeed, thresholds.highReleaseSpeedThreshold)
  }

  func testMediumControlledDragDoesNotDaze() {
    let metrics = metricsFrom(relativePoints: [
      (0, 0, 0),
      (0.5, 100, 0),
      (1.0, 200, 0),
      (1.5, 300, 0)
    ])
    XCTAssertEqual(classify(metrics), .normal)
  }

  func testTinyNudgeDoesNotDaze() {
    let metrics = metricsFrom(relativePoints: [
      (0, 0, 0),
      (0.4, 18, 4)
    ])
    XCTAssertEqual(classify(metrics), .normal)
  }

  func testFastFlingTriggersDaze() {
    let metrics = metricsFrom(relativePoints: [
      (0, 0, 0),
      (0.05, 120, 0),
      (0.10, 280, 0)
    ])
    XCTAssertGreaterThanOrEqual(metrics.netDisplacement, thresholds.minimumThrowDisplacement)
    XCTAssertGreaterThanOrEqual(metrics.releaseSpeed, thresholds.highReleaseSpeedThreshold)
    XCTAssertGreaterThanOrEqual(metrics.netToPathRatio, thresholds.minimumThrowNetToPathRatio)
    if case .dazed(let reason) = classify(metrics) {
      XCTAssertEqual(reason, .highReleaseSpeed)
    } else {
      XCTFail("Expected dazed for throw-like fling, got normal")
    }
  }

  func testHighReleaseSpeedTriggersDaze() {
    var tracker = OrbyDragGestureTracker()
    let t0 = Date(timeIntervalSinceReferenceDate: 0)
    tracker.begin(at: CGPoint(x: 0, y: 0), time: t0)
    tracker.addSample(at: CGPoint(x: 60, y: 0), time: t0.addingTimeInterval(0.03))
    tracker.addSample(at: CGPoint(x: 150, y: 0), time: t0.addingTimeInterval(0.06))
    let metrics = tracker.finish(at: CGPoint(x: 310, y: 0), time: t0.addingTimeInterval(0.11))
    if case .dazed(let reason) = classify(metrics) {
      XCTAssertEqual(reason, .highReleaseSpeed)
    } else {
      XCTFail("Expected dazed for throw-like release")
    }
  }

  func testHighPeakAndAverageSpeedTriggersDaze() {
    var tracker = OrbyDragGestureTracker()
    let t0 = Date(timeIntervalSinceReferenceDate: 0)
    tracker.begin(at: .zero, time: t0)
    for step in 1...5 {
      let x = CGFloat(step) * 95
      tracker.addSample(at: CGPoint(x: x, y: 0), time: t0.addingTimeInterval(Double(step) * 0.022))
    }
    let metrics = tracker.finish(at: CGPoint(x: 520, y: 0), time: t0.addingTimeInterval(0.13))
    XCTAssertGreaterThanOrEqual(metrics.peakSpeed, thresholds.highPeakSpeedThreshold)
    XCTAssertGreaterThanOrEqual(metrics.averageSpeed, thresholds.highAverageSpeedThreshold)
    XCTAssertGreaterThanOrEqual(metrics.releaseSpeed, thresholds.minimumViolentReleaseSpeed)
    if case .dazed(let reason) = classify(metrics) {
      XCTAssertEqual(reason, .highPeakSpeed)
    } else {
      XCTFail("Expected dazed for violent sustained drag")
    }
  }

  func testQuickRepositionDoesNotDaze() {
    let metrics = metricsFrom(relativePoints: [
      (0, 0, 0),
      (0.12, 90, 0),
      (0.24, 180, 0),
      (0.36, 260, 0)
    ])
    XCTAssertGreaterThan(metrics.netDisplacement, thresholds.minimumMovementForDazed)
    XCTAssertEqual(classify(metrics), .normal)
  }

  func testFastStraightDragWithoutThrowReleaseDoesNotDaze() {
    let metrics = metricsFrom(relativePoints: [
      (0, 0, 0),
      (0.08, 120, 0),
      (0.20, 220, 0),
      (0.55, 300, 0)
    ])
    XCTAssertGreaterThan(metrics.netDisplacement, 200)
    XCTAssertLessThan(metrics.releaseSpeed, thresholds.highReleaseSpeedThreshold)
    XCTAssertEqual(classify(metrics), .normal)
  }

  func testRapidShakeTriggersDaze() {
    let metrics = metricsFrom(relativePoints: [
      (0, 0, 0),
      (0.04, 100, 0),
      (0.08, 8, 0),
      (0.12, 110, 0),
      (0.16, 6, 0),
      (0.20, 105, 0),
      (0.24, 10, 0),
      (0.28, 95, 0),
      (0.32, 40, 0)
    ])
    XCTAssertGreaterThanOrEqual(metrics.directionChangeCount, thresholds.shakeDirectionChangeThreshold)
    XCTAssertGreaterThanOrEqual(metrics.pathLength, thresholds.shakeMinimumPathLength)
    XCTAssertLessThanOrEqual(metrics.netToPathRatio, thresholds.shakeNetToPathRatioMax + 0.05)
    if case .dazed(let reason) = classify(metrics) {
      XCTAssertEqual(reason, .shake)
    } else {
      XCTFail("Expected dazed for shake")
    }
  }

  func testLongDistanceAloneDoesNotDaze() {
    let metrics = metricsFrom(relativePoints: [
      (0, 0, 0),
      (5.0, 800, 0)
    ])
    XCTAssertGreaterThan(metrics.netDisplacement, 500)
    XCTAssertEqual(classify(metrics), .normal)
  }

  func testLowReleaseSpeedAfterLongDragDoesNotDaze() {
    let metrics = metricsFrom(relativePoints: [
      (0, 0, 0),
      (1.0, 150, 0),
      (2.0, 300, 0),
      (3.0, 420, 0),
      (3.8, 450, 0)
    ])
    XCTAssertLessThan(metrics.releaseSpeed, thresholds.highReleaseSpeedThreshold)
    XCTAssertEqual(classify(metrics), .normal)
  }

  func testDirectionNoiseUnderThresholdDoesNotShakeDaze() {
    let metrics = metricsFrom(relativePoints: [
      (0, 0, 0),
      (0.08, 8, 2),
      (0.16, 16, -1),
      (0.24, 24, 1),
      (0.32, 32, 0)
    ])
    XCTAssertLessThan(metrics.directionChangeCount, thresholds.shakeDirectionChangeThreshold)
    XCTAssertEqual(classify(metrics), .normal)
  }

  func testHighPathLengthLowSpeedDoesNotDaze() {
    let metrics = metricsFrom(relativePoints: [
      (0, 0, 0),
      (1.0, 20, 15),
      (2.0, 40, 30),
      (3.0, 60, 45),
      (4.0, 80, 60)
    ])
    XCTAssertGreaterThan(metrics.pathLength, 90)
    XCTAssertLessThan(metrics.peakSpeed, 400)
    XCTAssertEqual(classify(metrics), .normal)
  }

  func testHighNetDistanceLowSpeedDoesNotDaze() {
    let metrics = metricsFrom(relativePoints: [
      (0, 0, 0),
      (4.5, 700, 0)
    ])
    XCTAssertGreaterThan(metrics.netDisplacement, 600)
    XCTAssertLessThan(metrics.averageSpeed, 200)
    XCTAssertEqual(classify(metrics), .normal)
  }

  func testCarefulRepositionDoesNotDaze() {
    let metrics = metricsFrom(relativePoints: [
      (0, 0, 0),
      (0.6, 100, 0),
      (1.2, 200, 0),
      (2.0, 300, 0)
    ])
    XCTAssertEqual(classify(metrics), .normal)
  }

  // MARK: - Helpers

  private func classify(_ metrics: OrbyDragGestureMetrics) -> OrbyDragReleaseClassification {
    OrbyDragGestureClassifier.classify(metrics, thresholds: thresholds)
  }

  private func metricsFrom(relativePoints: [(TimeInterval, CGFloat, CGFloat)]) -> OrbyDragGestureMetrics {
    var tracker = OrbyDragGestureTracker()
    let base = Date(timeIntervalSinceReferenceDate: 10_000)
    guard let first = relativePoints.first else {
      return OrbyDragGestureMetricsBuilder.build(from: [])
    }
    tracker.begin(at: CGPoint(x: first.1, y: first.2), time: base.addingTimeInterval(first.0))
    for point in relativePoints.dropFirst() {
      tracker.addSample(
        at: CGPoint(x: point.1, y: point.2),
        time: base.addingTimeInterval(point.0)
      )
    }
    let last = relativePoints.last!
    return tracker.finish(
      at: CGPoint(x: last.1, y: last.2),
      time: base.addingTimeInterval(last.0)
    )
  }
}
