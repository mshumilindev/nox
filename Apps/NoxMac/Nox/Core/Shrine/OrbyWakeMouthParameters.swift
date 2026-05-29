import Foundation

/// Wake / sleep mouth presets — fixed width so UI animation never lerps toward default `width: 12`.
enum OrbyWakeMouthParameters {
  private static let slitWidth: CGFloat = 9
  private static let slitOvalWidth: CGFloat = 5.8
  private static let slitLineHeight: CGFloat = 2

  /// Shipped caps for 76 pt orb (see Orby wake mouth spec).
  private static let maxYawnWidth: CGFloat = 18
  private static let maxYawnHeight: CGFloat = 22
  private static let preferredYawnWidth: CGFloat = 16
  private static let preferredYawnHeight: CGFloat = 20
  private static let maxYawnVerticalOffset: CGFloat = 0.8

  static var closedSlit: OrbyMouthParameters {
    OrbyMouthParameters(
      width: slitWidth,
      lineHeight: slitLineHeight,
      cornerLift: 0,
      curvature: 0.5,
      openness: 0,
      ovalWidth: slitOvalWidth,
      ovalHeight: 5,
      verticalOffset: 0
    )
  }

  /// Sleepy line → vertical capsule → brief hold → close. `progress == 1` matches `closedSlit`.
  static func yawn(progress: Double) -> OrbyMouthParameters {
    let t = min(max(progress, 0), 1)
    let openness = yawnOpenness(t)

    var mouth = closedSlit
    mouth.openness = openness

    let widthT = CGFloat(openness)
    mouth.width = lerp(slitWidth, preferredYawnWidth, widthT)
    mouth.lineHeight = lerp(slitLineHeight, 2.2, widthT)
    mouth.ovalWidth = lerp(slitOvalWidth, preferredYawnWidth * 0.88, widthT)
    mouth.ovalHeight = lerp(5, preferredYawnHeight, widthT)
    mouth.verticalOffset = CGFloat(OrbyMiniVisualEasing.smoothstep(Double(openness))) * maxYawnVerticalOffset

    return clampYawn(mouth)
  }

  static func matchesClosedSlit(_ mouth: OrbyMouthParameters) -> Bool {
    let ref = closedSlit
    return abs(mouth.width - ref.width) < 0.01
      && abs(mouth.openness) < 0.02
      && abs(mouth.ovalWidth - ref.ovalWidth) < 0.01
  }

  private static func yawnOpenness(_ t: Double) -> CGFloat {
    if t < 0.22 {
      return CGFloat(OrbyMiniVisualEasing.smoothstep(t / 0.22)) * 0.32
    }
    if t < 0.48 {
      let p = OrbyMiniVisualEasing.smoothstep((t - 0.22) / 0.26)
      return CGFloat(0.32 + p * 0.68)
    }
    if t < 0.78 {
      return 1
    }
    let p = OrbyMiniVisualEasing.smoothstep((t - 0.78) / 0.22)
    return CGFloat(1 - p)
  }

  private static func clampYawn(_ mouth: OrbyMouthParameters) -> OrbyMouthParameters {
    var m = mouth
    m.width = min(max(m.width, slitWidth), maxYawnWidth)
    m.ovalWidth = min(max(m.ovalWidth, slitOvalWidth), maxYawnWidth)
    m.ovalHeight = min(max(m.ovalHeight, slitLineHeight + 1), maxYawnHeight)
    if m.ovalHeight < m.ovalWidth * 1.08 {
      m.ovalHeight = m.ovalWidth * 1.12
    }
    m.verticalOffset = min(max(m.verticalOffset, 0), maxYawnVerticalOffset)
    m.openness = min(max(m.openness, 0), 1)
    return m
  }

  private static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    a + (b - a) * min(max(t, 0), 1)
  }
}
