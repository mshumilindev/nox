import CoreGraphics
import Foundation

enum OrbyMeteorPathGenerator {
  static func randomMeteor(startedAt: TimeInterval) -> OrbyMeteorEvent {
    let angleDeg = Double.random(in: 20...55)
    let fromLeft = Bool.random()
    let direction = CGPoint.fromAngleDegrees(fromLeft ? angleDeg : 180 - angleDeg)
    let start = pointOnUnitCircle(facing: direction, outside: true)
    let end = pointOnUnitCircle(facing: CGPoint(x: -direction.x, y: -direction.y), outside: true)
    return makeMeteor(
      startedAt: startedAt,
      start: start,
      end: end,
      duration: Double.random(in: OrbyMiniVisualTiming.ambientMeteorDurationRange),
      color: pickMeteorColor()
    )
  }

  static func perseidShower(startedAt: TimeInterval) -> OrbyPerseidShowerEvent {
    let fromLeft = Bool.random()
    let baseAngle = fromLeft ? Double.random(in: 28...48) : Double.random(in: 132...152)
    let radiant = CGPoint.fromAngleDegrees(baseAngle - 90).scaled(1.25)
    let count = Int.random(in: 4...9)
    var meteors: [OrbyMeteorEvent] = []
    var stagger: TimeInterval = 0
    for _ in 0..<count {
      let spread = Double.random(in: -16...16)
      let direction = CGPoint.fromAngleDegrees(baseAngle + spread)
      let start = pointOnUnitCircle(facing: direction, outside: true, bias: radiant)
      let end = pointOnUnitCircle(facing: CGPoint(x: -direction.x, y: -direction.y), outside: true)
      let peak = CGFloat.random(in: 0.55...0.92)
      let meteorStart = startedAt + stagger
      meteors.append(
        makeMeteor(
          startedAt: meteorStart,
          start: start,
          end: end,
          duration: Double.random(in: 0.42...0.78),
          color: pickPerseidColor(bright: peak > 0.82),
          peakOpacity: peak
        )
      )
      stagger += Double.random(in: 0.15...0.7)
    }
    let duration = max(
      OrbyMiniVisualTiming.perseidShowerDurationSeconds,
      (meteors.last.map { $0.startedAt - startedAt + $0.duration }) ?? 3.5
    )
    return OrbyPerseidShowerEvent(
      id: UUID(),
      startedAt: startedAt,
      duration: duration,
      meteors: meteors,
      radiant: radiant
    )
  }

  private static func makeMeteor(
    startedAt: TimeInterval,
    start: CGPoint,
    end: CGPoint,
    duration: TimeInterval,
    color: OrbyMeteorColor,
    peakOpacity: CGFloat = CGFloat.random(in: 0.62...0.88)
  ) -> OrbyMeteorEvent {
    OrbyMeteorEvent(
      id: UUID(),
      startedAt: startedAt,
      duration: duration,
      start: start,
      end: end,
      headSize: CGFloat.random(in: 1.0...2.2),
      tailLength: CGFloat.random(in: 12...28),
      tailWidth: CGFloat.random(in: 0.5...1.4),
      color: color,
      peakOpacity: peakOpacity
    )
  }

  private static func pickMeteorColor() -> OrbyMeteorColor {
    let roll = Double.random(in: 0...1)
    if roll < 0.12 { return .paleCyan }
    if roll < 0.14 { return .paleRose }
    return .paleLavender
  }

  private static func pickPerseidColor(bright: Bool) -> OrbyMeteorColor {
    if bright { return .paleCyan }
    return Double.random(in: 0...1) < 0.7 ? .paleLavender : .paleCyan
  }

  private static func pointOnUnitCircle(facing direction: CGPoint, outside: Bool, bias: CGPoint? = nil) -> CGPoint {
    let dir = direction.normalized
    var angle = atan2(dir.y, dir.x)
    if let bias {
      angle = angle * 0.72 + atan2(bias.y, bias.x) * 0.28
    }
    angle += Double.random(in: -0.22...0.22)
    let radius = outside ? CGFloat.random(in: 1.05...1.18) : CGFloat.random(in: 0.82...0.98)
    return CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
  }
}

private extension CGPoint {
  static func fromAngleDegrees(_ degrees: Double) -> CGPoint {
    let rad = degrees * .pi / 180
    return CGPoint(x: cos(rad), y: sin(rad))
  }

  var normalized: CGPoint {
    let len = hypot(x, y)
    guard len > 0.0001 else { return CGPoint(x: 1, y: 0) }
    return CGPoint(x: x / len, y: y / len)
  }

  func scaled(_ factor: CGFloat) -> CGPoint {
    CGPoint(x: x * factor, y: y * factor)
  }
}
