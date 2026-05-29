import SwiftUI

/// Drawn "anime sparkle" eye for the `animeSelfSatisfied` beat. A dedicated layered
/// eye — not the scaled normal eye — that morphs in ("sparkle open") and back out.
struct OrbyAnimeEyeView: View {
  /// 0…1 reveal — drives a small scale-up + fade-in (no hard swap, no sticker crossfade).
  var reveal: Double
  var width: CGFloat = 10.5
  var height: CGFloat = 14

  var body: some View {
    let r = CGFloat(min(max(reveal, 0), 1))
    ZStack {
      // Outer pale lavender/white rounded vertical capsule.
      Capsule(style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.93, green: 0.94, blue: 1.0),
              Color(red: 0.82, green: 0.84, blue: 0.98)
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .overlay(
          Capsule(style: .continuous)
            .strokeBorder(Color(red: 0.55, green: 0.5, blue: 0.78).opacity(0.45), lineWidth: 0.6)
        )

      // Inner shine gradient (depth).
      Capsule(style: .continuous)
        .fill(
          RadialGradient(
            colors: [Color.white.opacity(0.95), Color(red: 0.74, green: 0.78, blue: 0.98).opacity(0.0)],
            center: UnitPoint(x: 0.4, y: 0.34),
            startRadius: 0.5,
            endRadius: width * 0.9
          )
        )
        .padding(0.8)

      // Lower lavender shading.
      Capsule(style: .continuous)
        .fill(
          LinearGradient(
            colors: [Color.clear, Color(red: 0.58, green: 0.52, blue: 0.86).opacity(0.5)],
            startPoint: .center,
            endPoint: .bottom
          )
        )
        .padding(0.8)

      // Main white highlight, upper-left.
      Circle()
        .fill(Color.white)
        .frame(width: width * 0.42, height: width * 0.42)
        .offset(x: -width * 0.18, y: -height * 0.24)

      // Secondary highlight, lower-right.
      Circle()
        .fill(Color.white.opacity(0.85))
        .frame(width: width * 0.2, height: width * 0.2)
        .offset(x: width * 0.2, y: height * 0.2)

      // Tiny 4-point glint.
      OrbyFourPointGlint()
        .fill(Color.white)
        .frame(width: width * 0.34, height: width * 0.34)
        .offset(x: width * 0.04, y: -height * 0.04)
        .opacity(0.9)
    }
    .frame(width: width, height: height)
    .scaleEffect(0.45 + 0.55 * r)
    .opacity(r)
  }
}

/// Stylized cat slit eye for `catMode`: pale outer, dark-violet vertical slit, taller/narrower.
struct OrbyCatEyeView: View {
  var reveal: Double
  var width: CGFloat = 6.5
  var height: CGFloat = 10

  var body: some View {
    let r = CGFloat(min(max(reveal, 0), 1))
    ZStack {
      Capsule(style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.95, green: 0.95, blue: 1.0),
              Color(red: 0.84, green: 0.85, blue: 0.98)
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
      // Centered vertical slit pupil.
      Capsule(style: .continuous)
        .fill(Color(red: 0.26, green: 0.16, blue: 0.42))
        .frame(width: max(1.4, width * 0.24), height: height * 0.82)
      // Tiny top catch-light.
      Circle()
        .fill(Color.white.opacity(0.9))
        .frame(width: width * 0.22, height: width * 0.22)
        .offset(x: -width * 0.12, y: -height * 0.26)
    }
    .frame(width: width, height: height)
    .scaleEffect(0.5 + 0.5 * r)
    .opacity(r)
  }
}

/// A small four-point sparkle (concave diamond) used for anime eye glints and accents.
struct OrbyFourPointGlint: Shape {
  func path(in rect: CGRect) -> Path {
    let c = CGPoint(x: rect.midX, y: rect.midY)
    let rx = rect.width / 2
    let ry = rect.height / 2
    let waist: CGFloat = 0.32
    var p = Path()
    p.move(to: CGPoint(x: c.x, y: c.y - ry))
    p.addQuadCurve(to: CGPoint(x: c.x + rx, y: c.y), control: CGPoint(x: c.x + rx * waist, y: c.y - ry * waist))
    p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + ry), control: CGPoint(x: c.x + rx * waist, y: c.y + ry * waist))
    p.addQuadCurve(to: CGPoint(x: c.x - rx, y: c.y), control: CGPoint(x: c.x - rx * waist, y: c.y + ry * waist))
    p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - ry), control: CGPoint(x: c.x - rx * waist, y: c.y - ry * waist))
    p.closeSubpath()
    return p
  }
}

/// Overlay row that places stylized eyes at the same centers as the normal eye row.
/// `slotWidth` mirrors the normal eye's layout frame (`metrics.width + 1`) so centers align.
struct OrbyStylizedEyeRow: View {
  enum Mode { case anime, cat }
  var mode: Mode
  var reveal: Double
  var leftSlotWidth: CGFloat
  var rightSlotWidth: CGFloat
  var spacing: CGFloat

  var body: some View {
    HStack(spacing: spacing) {
      slot(width: leftSlotWidth)
      slot(width: rightSlotWidth)
    }
  }

  @ViewBuilder
  private func slot(width: CGFloat) -> some View {
    ZStack {
      switch mode {
      case .anime: OrbyAnimeEyeView(reveal: reveal)
      case .cat: OrbyCatEyeView(reveal: reveal)
      }
    }
    .frame(width: width, alignment: .center)
  }
}
