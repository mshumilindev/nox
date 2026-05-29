import CoreGraphics
import Foundation
import os

// MARK: - Samples & metrics

struct OrbyDragSample: Equatable {
  let time: TimeInterval
  let point: CGPoint
}

struct OrbyDragGestureMetrics: Equatable {
  let duration: TimeInterval
  /// Straight-line distance from first to last sample.
  let totalDistance: CGFloat
  let pathLength: CGFloat
  let netDisplacement: CGFloat
  let averageSpeed: CGFloat
  let peakSpeed: CGFloat
  let releaseSpeed: CGFloat
  let peakAcceleration: CGFloat
  let directionChangeCount: Int
  let jerkScore: CGFloat

  var netToPathRatio: CGFloat {
    guard pathLength > 0.5 else { return 1 }
    return netDisplacement / pathLength
  }
}

enum OrbyDazedTriggerReason: Equatable {
  case highReleaseSpeed
  case highPeakSpeed
  case shake
  case highAcceleration
  case combinedScore
}

enum OrbyDragReleaseClassification: Equatable {
  case normal
  case dazed(reason: OrbyDazedTriggerReason)
}

// MARK: - Thresholds

struct OrbyDragDazedThresholds: Equatable {
  /// Ignore micro-taps and jitter.
  var minimumDragDurationForDazed: TimeInterval = 0.08
  var minimumMovementForDazed: CGFloat = 40
  /// Throw-like fling: hot release on a mostly straight, short gesture.
  var minimumThrowDisplacement: CGFloat = 96
  var minimumThrowNetToPathRatio: CGFloat = 0.68
  var maximumThrowDuration: TimeInterval = 0.42
  var highReleaseSpeedThreshold: CGFloat = 2600
  var minimumThrowPeakSpeed: CGFloat = 2200
  /// Sustained violent drag (rare); still requires a hot release.
  var highPeakSpeedThreshold: CGFloat = 3400
  var highAverageSpeedThreshold: CGFloat = 1500
  var minimumViolentReleaseSpeed: CGFloat = 2000
  var minimumViolentDisplacement: CGFloat = 110
  var highAccelerationThreshold: CGFloat = 12_000
  var minimumAccelerationPeakSpeed: CGFloat = 2400
  var shakeDirectionChangeThreshold: Int = 5
  var shakeMinimumPathLength: CGFloat = 200
  var shakeNetToPathRatioMax: CGFloat = 0.48
  var shakeMinimumPeakSpeed: CGFloat = 1600
  var shakeMinimumDisplacement: CGFloat = 35
  var directionChangeMinSegmentLength: CGFloat = 14
  var directionChangeAngleDegrees: CGFloat = 65
  var releaseSpeedWindowSeconds: TimeInterval = 0.10
}

// MARK: - Tracker

/// In-memory drag path collector (cleared on finish / cancel).
struct OrbyDragGestureTracker {
  private(set) var samples: [OrbyDragSample] = []

  mutating func begin(at point: CGPoint, time: Date = Date()) {
    samples = [OrbyDragSample(time: time.timeIntervalSinceReferenceDate, point: point)]
  }

  mutating func addSample(at point: CGPoint, time: Date = Date()) {
    let sample = OrbyDragSample(time: time.timeIntervalSinceReferenceDate, point: point)
    if let last = samples.last, last.point == point, abs(last.time - sample.time) < 0.0001 {
      return
    }
    samples.append(sample)
  }

  mutating func finish(at point: CGPoint, time: Date = Date()) -> OrbyDragGestureMetrics {
    addSample(at: point, time: time)
    let metrics = OrbyDragGestureMetricsBuilder.build(from: samples)
    samples = []
    return metrics
  }

  mutating func cancel() {
    samples = []
  }
}

// MARK: - Metrics builder

enum OrbyDragGestureMetricsBuilder {
  static func build(from samples: [OrbyDragSample]) -> OrbyDragGestureMetrics {
    guard let first = samples.first, let last = samples.last, samples.count >= 1 else {
      return OrbyDragGestureMetrics(
        duration: 0, totalDistance: 0, pathLength: 0, netDisplacement: 0,
        averageSpeed: 0, peakSpeed: 0, releaseSpeed: 0, peakAcceleration: 0,
        directionChangeCount: 0, jerkScore: 0
      )
    }

    let duration = max(last.time - first.time, 0)
    let netDisplacement = hypot(last.point.x - first.point.x, last.point.y - first.point.y)

    var pathLength: CGFloat = 0
    var peakSpeed: CGFloat = 0
    var peakAcceleration: CGFloat = 0
    var previousAngle: CGFloat?
    var directionChangeCount = 0
    var previousSpeed: CGFloat?
    var jerkAccum: CGFloat = 0
    var jerkCount = 0

    let minSegment = OrbyDragDazedThresholds().directionChangeMinSegmentLength
    let angleThreshold = OrbyDragDazedThresholds().directionChangeAngleDegrees * .pi / 180

    if samples.count >= 2 {
      for index in 1..<samples.count {
        let a = samples[index - 1]
        let b = samples[index]
        let dx = b.point.x - a.point.x
        let dy = b.point.y - a.point.y
        let segment = hypot(dx, dy)
        let dt = max(b.time - a.time, 0.0001)
        pathLength += segment

        let speed = segment / CGFloat(dt)
        peakSpeed = max(peakSpeed, speed)

        if let previousSpeed {
          let accel = abs(speed - previousSpeed) / CGFloat(dt)
          peakAcceleration = max(peakAcceleration, accel)
          jerkAccum += accel
          jerkCount += 1
        }
        previousSpeed = speed

        if segment >= minSegment {
          let angle = atan2(dy, dx)
          if let prev = previousAngle {
            var delta = abs(angle - prev)
            if delta > .pi { delta = 2 * .pi - delta }
            if delta >= angleThreshold {
              directionChangeCount += 1
            }
          }
          previousAngle = angle
        }
      }
    }

    let averageSpeed = duration > 0 ? pathLength / CGFloat(duration) : 0
    let releaseSpeed = releaseSpeed(samples: samples, window: OrbyDragDazedThresholds().releaseSpeedWindowSeconds)
    let jerkScore = jerkCount > 0 ? jerkAccum / CGFloat(jerkCount) : 0

    return OrbyDragGestureMetrics(
      duration: duration,
      totalDistance: netDisplacement,
      pathLength: pathLength,
      netDisplacement: netDisplacement,
      averageSpeed: averageSpeed,
      peakSpeed: peakSpeed,
      releaseSpeed: releaseSpeed,
      peakAcceleration: peakAcceleration,
      directionChangeCount: directionChangeCount,
      jerkScore: jerkScore
    )
  }

  private static func releaseSpeed(samples: [OrbyDragSample], window: TimeInterval) -> CGFloat {
    guard samples.count >= 2, let last = samples.last else { return 0 }
    let cutoff = last.time - window
    var speeds: [CGFloat] = []
    for index in 1..<samples.count {
      let a = samples[index - 1]
      let b = samples[index]
      guard b.time >= cutoff else { continue }
      let dt = max(b.time - a.time, 0.0001)
      let dx = b.point.x - a.point.x
      let dy = b.point.y - a.point.y
      speeds.append(hypot(dx, dy) / CGFloat(dt))
    }
    guard !speeds.isEmpty else { return 0 }
    return speeds.reduce(0, +) / CGFloat(speeds.count)
  }
}

// MARK: - Classifier

enum OrbyDragGestureClassifier {
  private static let log = Logger(subsystem: "dev.nox", category: "OrbyDragDazed")

  static func classify(
    _ metrics: OrbyDragGestureMetrics,
    thresholds: OrbyDragDazedThresholds = OrbyDragDazedThresholds()
  ) -> OrbyDragReleaseClassification {
    let result = classifyInternal(metrics, thresholds: thresholds)
    #if DEBUG
    logDebug(metrics: metrics, classification: result)
    #endif
    return result
  }

  private static func classifyInternal(
    _ m: OrbyDragGestureMetrics,
    thresholds t: OrbyDragDazedThresholds
  ) -> OrbyDragReleaseClassification {
    guard m.duration >= t.minimumDragDurationForDazed else { return .normal }
    guard m.netDisplacement >= t.minimumMovementForDazed else { return .normal }

    // A. Sustained violent drag — still needs a hot release (not a slow carry).
    if m.peakSpeed >= t.highPeakSpeedThreshold
      && m.averageSpeed >= t.highAverageSpeedThreshold
      && m.releaseSpeed >= t.minimumViolentReleaseSpeed
      && m.netDisplacement >= t.minimumViolentDisplacement
      && m.duration >= 0.12 {
      return .dazed(reason: .highPeakSpeed)
    }

    // B. Throw / fling — straight, short, released very fast (normal reposition fails here).
    if isThrowLike(m, thresholds: t) {
      return .dazed(reason: .highReleaseSpeed)
    }

    // C. Shake — aggressive zig-zag only.
    if m.directionChangeCount >= t.shakeDirectionChangeThreshold
      && m.pathLength >= t.shakeMinimumPathLength
      && m.netDisplacement >= t.shakeMinimumDisplacement
      && m.netToPathRatio <= t.shakeNetToPathRatioMax
      && m.peakSpeed >= t.shakeMinimumPeakSpeed {
      return .dazed(reason: .shake)
    }

    // D. Violent jerk / stop (rare).
    if m.peakAcceleration >= t.highAccelerationThreshold
      && m.peakSpeed >= t.minimumAccelerationPeakSpeed
      && m.releaseSpeed >= t.minimumViolentReleaseSpeed
      && m.netDisplacement >= t.minimumThrowDisplacement {
      return .dazed(reason: .highAcceleration)
    }

    return .normal
  }

  /// Matches “threw the orb” — not a quick cursor reposition.
  private static func isThrowLike(
    _ m: OrbyDragGestureMetrics,
    thresholds t: OrbyDragDazedThresholds
  ) -> Bool {
    m.duration <= t.maximumThrowDuration
      && m.netDisplacement >= t.minimumThrowDisplacement
      && m.netToPathRatio >= t.minimumThrowNetToPathRatio
      && m.releaseSpeed >= t.highReleaseSpeedThreshold
      && m.peakSpeed >= t.minimumThrowPeakSpeed
  }

  #if DEBUG
  private static func logDebug(
    metrics m: OrbyDragGestureMetrics,
    classification: OrbyDragReleaseClassification
  ) {
    let reason: String
    switch classification {
    case .normal:
      reason = "normal"
    case .dazed(let r):
      reason = String(describing: r)
    }
    log.debug(
      """
      Orby drag classify: \(reason, privacy: .public) \
      dur=\(m.duration, privacy: .public)s path=\(m.pathLength, privacy: .public) \
      net=\(m.netDisplacement, privacy: .public) avg=\(m.averageSpeed, privacy: .public) \
      peak=\(m.peakSpeed, privacy: .public) release=\(m.releaseSpeed, privacy: .public) \
      accel=\(m.peakAcceleration, privacy: .public) turns=\(m.directionChangeCount, privacy: .public) \
      net/path=\(m.netToPathRatio, privacy: .public)
      """
    )
  }
  #endif
}
