import CoreGraphics
import SwiftUI

/// Readable upright Z stream above upper-right rim (isolated from face transforms).
struct OrbyZzzView: View {
  let opacity: Double
  var backgroundLuminance: Double = 0.5

  private let orbRadius: CGFloat = 38
  private let groupShift = CGPoint(x: 5, y: -7)
  private let cycleSeconds: TimeInterval = 4.2

  /// Path follows the current arranged diagonal: from rim-adjacent to up/out.
  private static let pathOffsets: [CGPoint] = [
    CGPoint(x: 22, y: -28),
    lerpOffset(from: CGPoint(x: 34, y: -42), toward: CGPoint(x: 22, y: -28), amount: 0.2),
    lerpOffset(from: CGPoint(x: 45, y: -54), toward: CGPoint(x: 22, y: -28), amount: 0.2)
  ]
  private let glyphs: [(character: String, size: CGFloat, weight: Font.Weight, phaseOffset: Double)] = [
    ("Z", 11.5, .semibold, 0.00),
    ("Z", 13.0, .bold, 0.25),
    ("z", 10.5, .medium, 0.50),
    ("z", 8.8, .medium, 0.75)
  ]

  private static func lerpOffset(from: CGPoint, toward: CGPoint, amount: CGFloat) -> CGPoint {
    CGPoint(
      x: from.x + (toward.x - from.x) * amount,
      y: from.y + (toward.y - from.y) * amount
    )
  }

  var body: some View {
    Group {
      if opacity > 0.01 {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
          let time = timeline.date.timeIntervalSinceReferenceDate
          ZStack {
            ForEach(Array(glyphs.enumerated()), id: \.offset) { index, spec in
              OrbyZzzGlyph(
                character: spec.character,
                size: spec.size,
                weight: spec.weight,
                path: Self.pathOffsets.map {
                  CGPoint(x: orbRadius + $0.x + groupShift.x, y: orbRadius + $0.y + groupShift.y)
                },
                time: time,
                phaseOffset: spec.phaseOffset,
                cycleSeconds: cycleSeconds,
                parentOpacity: opacity,
                backgroundLuminance: backgroundLuminance
              )
            }
          }
          .frame(width: 76, height: 76)
        }
      }
    }
  }
}

private struct OrbyZzzGlyph: View {
  let character: String
  let size: CGFloat
  let weight: Font.Weight
  let path: [CGPoint]
  let time: TimeInterval
  let phaseOffset: Double
  let cycleSeconds: TimeInterval
  let parentOpacity: Double
  let backgroundLuminance: Double

  var body: some View {
    strokedText
      .position(animatedPosition)
      .opacity(animatedOpacity)
      .scaleEffect(animatedScale)
  }

  private var animatedPosition: CGPoint {
    guard path.count >= 3 else { return .zero }
    let t = progress
    let eased = OrbyZzzMotion.easeOut(t)
    let wobble = CGFloat(sin((time * 2.2) + phaseOffset * 8.0)) * 0.55 * sin(t * .pi)
    if eased < 0.55 {
      let local = eased / 0.55
      let p = OrbyZzzMotion.lerp(path[0], path[1], local)
      return CGPoint(x: p.x + wobble, y: p.y - wobble * 0.35)
    }
    let local = (eased - 0.55) / 0.45
    let p = OrbyZzzMotion.lerp(path[1], path[2], local)
    return CGPoint(x: p.x + wobble, y: p.y - wobble * 0.35)
  }

  private var animatedOpacity: Double {
    let t = progress
    let fadeIn = OrbyZzzMotion.smoothstep(min(t / 0.34, 1))
    let fadeOut = 1 - OrbyZzzMotion.smoothstep(max((t - 0.66) / 0.34, 0))
    return min(0.88, parentOpacity * fadeIn * fadeOut)
  }

  private var animatedScale: CGFloat {
    let t = progress
    let grow = 0.70 + CGFloat(OrbyZzzMotion.smoothstep(min(t / 0.34, 1))) * 0.30
    let shrink = 1 - CGFloat(OrbyZzzMotion.smoothstep(max((t - 0.66) / 0.34, 0))) * 0.42
    return grow * shrink
  }

  private var progress: Double {
    let raw = (time / cycleSeconds + phaseOffset).truncatingRemainder(dividingBy: 1)
    return raw < 0 ? raw + 1 : raw
  }

  private var strokedText: some View {
    let lightBackground = backgroundLuminance > 0.52
    let fill = lightBackground
      ? Color(red: 0.47, green: 0.24, blue: 0.98)
      : Color(red: 0.88, green: 0.78, blue: 1.0)
    let shadow = lightBackground
      ? Color(red: 0.17, green: 0.06, blue: 0.32).opacity(0.32)
      : Color.black.opacity(0.36)
    return ZStack {
      Text(character)
        .font(.system(size: size, weight: weight, design: .rounded))
        .foregroundStyle(shadow)
        .offset(x: 0.4, y: 0.45)
      Text(character)
        .font(.system(size: size, weight: weight, design: .rounded))
        .foregroundStyle(fill)
    }
  }
}

private enum OrbyZzzMotion {
  static func smoothstep(_ t: Double) -> Double {
    let x = min(max(t, 0), 1)
    return x * x * (3 - 2 * x)
  }

  static func easeOut(_ t: Double) -> Double {
    let x = min(max(t, 0), 1)
    return 1 - pow(1 - x, 2.2)
  }

  static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
    let p = CGFloat(min(max(t, 0), 1))
    return CGPoint(
      x: a.x + (b.x - a.x) * p,
      y: a.y + (b.y - a.y) * p
    )
  }
}

typealias ShrineMiniZzzView = OrbyZzzView
