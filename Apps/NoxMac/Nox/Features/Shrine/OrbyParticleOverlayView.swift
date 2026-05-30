import SwiftUI

/// Sparse symbolic particles (steam, sparks, glints, thought dots, alarm ring).
struct OrbyParticleOverlayView: View {
  let particle: OrbyOverlayParticle
  let opacity: Double
  var backgroundLuminance: Double = 0.5

  private let center: CGFloat = 38
  private let orbRadius: CGFloat = 38

  var body: some View {
    Group {
      if opacity > 0.02 && particle != .none {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
          let t = timeline.date.timeIntervalSinceReferenceDate
          ZStack {
            switch particle {
            case .none:
              EmptyView()
            case .steamPuffs(let count):
              ForEach(0..<count, id: \.self) { i in
                steamPuff(index: i, time: t)
              }
            case .sparks(let count):
              ForEach(0..<count, id: \.self) { i in
                spark(index: i, time: t)
              }
            case .glints(let count):
              ForEach(0..<count, id: \.self) { i in
                glint(index: i, time: t)
              }
            case .thoughtDots(let count):
              ForEach(0..<count, id: \.self) { i in
                thoughtDot(index: i, time: t)
              }
            case .alarmRing:
              alarmRing(time: t)
            case .helloSyllables(let progress):
              helloWordFragment(
                "He",
                progress: progress,
                launchAt: OrbyLaunchGreetingSyllableTiming.heLaunchProgress,
                arriveAt: OrbyLaunchGreetingSyllableTiming.heArriveProgress,
                holdEndAt: OrbyLaunchGreetingSyllableTiming.wordHoldEndProgress,
                fadeEndAt: OrbyLaunchGreetingSyllableTiming.wordFadeEndProgress,
                mouthStart: OrbyLaunchGreetingSyllableTiming.mouthLaunch,
                joinPoint: OrbyLaunchGreetingSyllableTiming.heJoinPoint
              )
              helloWordFragment(
                "llo",
                progress: progress,
                launchAt: OrbyLaunchGreetingSyllableTiming.lloLaunchProgress,
                arriveAt: OrbyLaunchGreetingSyllableTiming.lloArriveProgress,
                holdEndAt: OrbyLaunchGreetingSyllableTiming.wordHoldEndProgress,
                fadeEndAt: OrbyLaunchGreetingSyllableTiming.wordFadeEndProgress,
                mouthStart: OrbyLaunchGreetingSyllableTiming.mouthLaunch,
                joinPoint: OrbyLaunchGreetingSyllableTiming.lloJoinPoint
              )
            }
          }
          .frame(width: 76, height: 76)
        }
      }
    }
  }

  @ViewBuilder
  private func steamPuff(index: Int, time: TimeInterval) -> some View {
    let phase = time * 0.9 + Double(index) * 1.4
    let x = center + CGFloat(index - 1) * 10
    let y = center - 42 - CGFloat(sin(phase)) * 4
    Circle()
      .fill(Color.white.opacity(0.55))
      .frame(width: 5 + CGFloat(index), height: 5 + CGFloat(index))
      .blur(radius: 1.2)
      .position(x: x, y: y)
      .opacity(opacity * (0.35 + 0.25 * sin(phase)))
  }

  @ViewBuilder
  private func spark(index: Int, time: TimeInterval) -> some View {
    let angle = Double(index) * 1.8 + time * 1.2
    let r: CGFloat = 20 + CGFloat(index) * 3
    Circle()
      .fill(Color(red: 1, green: 0.75, blue: 0.45).opacity(0.85))
      .frame(width: 3.5, height: 3.5)
      .position(
        x: center + cos(angle) * r,
        y: center + sin(angle) * r * 0.6 - 8
      )
      .opacity(opacity * 0.7)
  }

  @ViewBuilder
  private func glint(index: Int, time: TimeInterval) -> some View {
    let x = center + 22 + CGFloat(index) * 6
    let y = center - 18 - CGFloat(index) * 4
    Text("✦")
      .font(.system(size: 5 + CGFloat(index), weight: .medium))
      .foregroundStyle(Color.white.opacity(0.75))
      .position(x: x, y: y)
      .opacity(opacity * (0.4 + 0.3 * sin(time + Double(index))))
  }

  @ViewBuilder
  private func thoughtDot(index: Int, time: TimeInterval) -> some View {
    let baseX = center + 20 + CGFloat(index) * 5
    let baseY = center - 28 - CGFloat(index) * 6
    Circle()
      .fill(Color(red: 0.75, green: 0.85, blue: 1).opacity(0.8))
      .frame(width: 3 + CGFloat(index) * 0.5, height: 3 + CGFloat(index) * 0.5)
      .position(
        x: baseX + CGFloat(sin(time * 0.5 + Double(index)) * 2),
        y: baseY + CGFloat(cos(time * 0.45 + Double(index)) * 2)
      )
      .opacity(opacity * 0.65)
  }

  @ViewBuilder
  private func alarmRing(time: TimeInterval) -> some View {
    let pulse = 0.5 + 0.5 * sin(time * 2.2)
    Circle()
      .stroke(Color(red: 1, green: 0.72, blue: 0.35).opacity(0.55 + pulse * 0.25), lineWidth: 1.5)
      .frame(width: 82, height: 82)
      .position(x: center, y: center)
      .opacity(opacity * 0.75)
  }

  @ViewBuilder
  private func helloWordFragment(
    _ text: String,
    progress: Double,
    launchAt: Double,
    arriveAt: Double,
    holdEndAt: Double,
    fadeEndAt: Double,
    mouthStart: CGPoint,
    joinPoint: CGPoint
  ) -> some View {
    let p = min(max(progress, 0), 1)
    if p > launchAt, p < fadeEndAt {
      let travelSpan = max(arriveAt - launchAt, 0.001)
      let travel = min(max((p - launchAt) / travelSpan, 0), 1)
      let eased = OrbyParticleMotion.easeOutCubic(travel)
      let atPeak = p >= arriveAt
      let x = atPeak ? joinPoint.x : mouthStart.x + (joinPoint.x - mouthStart.x) * CGFloat(eased)
      let y = atPeak ? joinPoint.y : mouthStart.y + (joinPoint.y - mouthStart.y) * CGFloat(eased)
      // Gentler appearance: longer ease-in and a slow ease-out so the syllables
      // are never abrupt.
      let fadeIn = OrbyParticleMotion.smoothstep(min((p - launchAt) / 0.18, 1))
      let fadeOut = p < holdEndAt
        ? 0.0
        : OrbyParticleMotion.smoothstep((p - holdEndAt) / max(fadeEndAt - holdEndAt, 0.001))
      let visibility = fadeIn * (1 - fadeOut)
      let settle = atPeak ? OrbyParticleMotion.smoothstep(min((p - arriveAt) / 0.14, 1)) : eased
      let color = helloColor(at: CGPoint(x: x, y: y))
      Text(text)
        .font(.system(size: 8.5, weight: .bold, design: .rounded))
        .foregroundStyle(
          LinearGradient(
            colors: [
              color.opacity(0.98),
              color.opacity(0.80)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .shadow(color: helloShadowColor(at: CGPoint(x: x, y: y)), radius: 3, x: 0, y: 0)
        .position(x: x, y: y)
        .scaleEffect(0.94 + CGFloat(settle) * 0.10 - CGFloat(fadeOut) * 0.05)
        .rotationEffect(.degrees(text == "He" ? -2 + CGFloat(settle) * 2 : -1 + CGFloat(settle) * 1.5))
        .opacity(opacity * min(1, visibility))
    }
  }

  private func helloColor(at point: CGPoint) -> Color {
    if isInsideOrb(point) { return .white }
    if backgroundLuminance > 0.52 {
      // Project deep purple for legibility on light backgrounds.
      return Color(red: 0.23, green: 0.07, blue: 0.52)
    }
    return .white
  }

  private func helloShadowColor(at point: CGPoint) -> Color {
    if isInsideOrb(point) {
      return Color(red: 0.15, green: 0.08, blue: 0.34).opacity(0.55)
    }
    if backgroundLuminance > 0.52 {
      return Color.white.opacity(0.38)
    }
    return Color(red: 0.50, green: 0.32, blue: 1.0).opacity(0.45)
  }

  private func isInsideOrb(_ point: CGPoint) -> Bool {
    let dx = point.x - center
    let dy = point.y - center
    return sqrt(dx * dx + dy * dy) <= orbRadius - 1
  }
}

private enum OrbyParticleMotion {
  static func easeOutCubic(_ t: Double) -> Double {
    let x = min(max(t, 0), 1)
    return 1 - pow(1 - x, 3)
  }

  static func pulse(_ progress: Double, start: Double, peak: Double, end: Double) -> Double {
    guard progress > start, progress < end else { return 0 }
    if progress <= peak {
      return smoothstep((progress - start) / (peak - start))
    }
    return 1 - smoothstep((progress - peak) / (end - peak))
  }

  static func smoothstep(_ t: Double) -> Double {
    let x = min(max(t, 0), 1)
    return x * x * (3 - 2 * x)
  }
}
